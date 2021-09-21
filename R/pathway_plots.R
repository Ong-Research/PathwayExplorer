
#' Plots a dotplot with the gsea results
#' @param gsea a `tibble::tibble` with the gsea results
dotplot <- function(gsea) {
  out <- gsea %>%
    ggplot(aes(x = nes, y = pathway,
               size = size, fill = padj, text = pathway)) +
    geom_point(shape = 21, aes(colour = in_lead)) +
    scale_fill_viridis_c(option = "A", direction = -1) +
    geom_vline(xintercept = 0, linetype = 2) +
    theme_minimal() +
    guides(colour = FALSE) +
    theme(
      legend.position = "none",
      axis.text = element_text(size = 6),
      axis.title.y = element_blank()) +
    scale_color_manual(values = c(`FALSE` = "black", `TRUE` = "orange")) +
    labs(
      x = "GSEA normalized enrichment score",
      y = "pathway",
      colour = "adjust p.value",
      size = "# genes")
  ggplotly(out, tooltip = "text", source = "dotplot") %>% 
    config(displaylogo = FALSE)
}