

#' Plots a volcano plot of the results of DE genes
#' @param results 
volcano_plot <- function(results, padj_thr = 1e-4, log2fc_thr = 1.5) {
  
  results %<>%
    dplyr::mutate(
      padj = if_else(padj == 0, min(padj[padj > 0]), padj))
    

  init_plot <- results %>%
    ggplot(aes(text = gene, x = log2fc, y = - log10(padj), colour = in_pathway)) +
    geom_point(size = 0.5) +
    scale_color_manual(values = c(`CC` = "navyblue", `BB` = "red", `AA` = "orange")) +
    labs(
      x = "log2 fold change",
      y = "-log[10](fdr)") +
    geom_vline(xintercept = log2fc_thr * c(-1, 1), linetype = 2,
               colour = "red") +
    geom_hline(yintercept = - log10(padj_thr), linetype = 2,
               colour = "red") +
    cowplot::theme_minimal_grid() +
    theme(legend.title = element_blank(), legend.position = "top")
  
  ggplotly(init_plot, tooltip = "text", source = "volcano") %>%
    hide_legend() %>% 
    config(displaylogo = FALSE)
}