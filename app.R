#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinythemes)

source(here::here("global.R"))

# Define UI for application that draws a histogram
ui <- fluidPage(
  theme = shinythemes::shinytheme("cosmo"),
  # Application title
  navbarPage("Pathway explorer",
    tabPanel("Analysis",
      sidebarLayout(
        sidebarPanel = sidebarPanel(
          "Parameters", width = 3,
          introBox(
            fileInput("genefile", "DE Genes file"),
            data.step = 1,
            data.intro = "This is the table of DE genes"),
              
          fileInput("pathfile", "Pathway file"),
          sliderInput("log10padj", expression(-log[10](`fdr`)),
            min = 0, max = 80, value = -log10(1e-3), step = .05),
          sliderInput("log2fc", expression(log[10](`FC`)),
            min = 0, max = 4, value = .5, step = 0.01),
          textInput("padj_path", "adjust p.value", "0.05")),
        mainPanel = mainPanel(
          width = 9,
          uiOutput("msigdb"),
          splitLayout(
            cellWidths = c("50%", "50%"),
            plotlyOutput("volcano"), plotlyOutput("dotplot")),
          DT::dataTableOutput("genetable")
        )
      )
    )
  )

)

# Define server logic required to draw a histogram
server <- function(input, output) {

    
    de_genes <- reactive({
      if (!is.null(input$genefile)) {
        read_de_file(input$genefile$datapath) %>%
          dplyr::rename(log2fc = log2FoldChange) %>%
          dplyr::filter(abs(log2fc) <= 1e3) %>%
          dplyr::mutate(in_pathway = "CC")
      } else {
        tibble::tibble() 
      }
    })
    
    pathways <- reactive({
      stopifnot(tools::file_ext(input$pathfile$datapath) == "gmt")
      if (!is.null(input$pathfile)) {
        qusage::read.gmt(input$pathfile$datapath)
      } else {
        list()
      }
    })
    
    gsea <- reactive({
      if (nrow(de_genes()) > 0 & length(pathways()) > 0) {
        genes <- de_genes()
        genes %<>%
          dplyr::filter(padj <= exp(-input$log10padj)) %>% 
          dplyr::filter(abs(log2fc) >= input$log2fc)
        ranks <- sign(genes$log2fc) * sqrt(genes$stat)
        names(ranks) <- genes$gene
        fgsea::fgseaSimple(pathways(), ranks, nperm = 1000,
          minSize = 15, maxSize = 500,
          BPPARAM = BiocParallel::MulticoreParam(workers = 1)) %>%
        tibble::as_tibble() %>%
        dplyr::rename_all(snakecase::to_snake_case) %>%
        dplyr::filter(!str_detect(pathway, regex("UNKNOWN$"))) %>% 
        dplyr::filter(padj <= as.numeric(input$padj_path)) %>% 
        dplyr::mutate(pathway = forcats::fct_reorder(pathway,nes))
        
      } else {
        tibble::tibble()
      }
    })

    pathway_click <- reactive({
      out <- event_data("plotly_click", "dotplot")
      if (!is.null(out)) {
        levels(gsea()$pathway)[out$y]
      }
    })
    
    volcano_click <- reactive({
      out <- event_data("plotly_click", "volcano")
      if (!is.null(out)) {
        de_genes() %>% 
          dplyr::filter(abs(log2fc / out$x - 1) <= 1e-6) %>%
          dplyr::filter(abs(-log10(padj) / out$y - 1) <= 1e-6) %>% 
          pull(gene)
      }
    })
    

    output$dotplot <- renderPlotly({
      gs <- gsea()
      if (nrow(gs) == 0) {
        ggplotly(ggplot()) %>% 
          config(displaylogo = FALSE)
      } else {
        vc <- volcano_click()
        if (!is.null(vc)) {
          gs %<>%
            mutate(
              in_lead = map_lgl(leading_edge, ~ any(. == vc)))
        } else {
          gs %<>%
            mutate(in_lead = FALSE)
        }
        dotplot(gs)
      }
        
    })
    
    output$volcano <- renderPlotly({
      if (nrow(de_genes()) == 0) {
        ggplotly(ggplot()) %>% 
          config(displaylogo = FALSE)
      } else {
        genes <- de_genes()
        pc <- pathway_click()
        if (!is.null(pc)) {
          pc_genes <- pathways()[[pc]]
          leading_genes <- gsea() %>%
            filter(pathway == pc) %>%
            pull(leading_edge) %>%
            pluck(1)
          genes %<>%
            mutate(
              in_pathway = case_when(
                gene %in% leading_genes ~ "AA",
                gene %in% pc_genes ~ "BB",
                TRUE ~ "CC"))
        }
        volcano_plot(genes,
          padj_thr = 10^(-input$log10padj), log2fc_thr = input$log2fc)
      }
    })
 
    output$msigdb <- renderUI({
      ll <- "https://www.gsea-msigdb.org/gsea/msigdb/"
      pc <- pathway_click()
      url <- a("Please download more SYMBOL pathways from MsigDB", href = ll)
      if (!is.null(pc)) {
        ll <- str_c(ll, "cards/", pc)
        url <- a(str_c("MsigDB:", pc, sep = " "), href = ll)
      }
      tagList("", url)
    })
    
    output$genetable <- renderDataTable({
      pc <- pathway_click()
      if (is.null(pc)) {
        tibble::tibble()
      } else {
        pc_genes <- pathways()[[pc]]
        leading_genes <- gsea() %>%
          filter(pathway == pc) %>%
          pull(leading_edge) %>%
          pluck(1)
        de_genes() %>%
          dplyr::filter(gene %in% pc_genes) %>%
          dplyr::mutate(
            leading = if_else(gene %in% leading_genes, "yes", "no"),
            log2fc = scales::comma(log2fc, .01),
            padj = scales::comma(-log10(padj), .01)) %>%
          dplyr::select(gene, leading, log2fc, padj) %>% 
          arrange(desc(leading), desc(padj)) %>%
          datatable(options = list(pageLength = 5))
      }
    })

  
    
           
}


# Run the application 
shinyApp(ui = ui, server = server)
