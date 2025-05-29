# Fine-Tuning Benchmarking

#### Fine-tune quantized Llama-2-70B model using MLCommons methodology for infrastructure benchmarking

The fine-tuning benchmarking blueprint streamlines infrastructure benchmarking for fine-tuning using the MLCommons methodology. It fine-tunes a quantized Llama-2-70B model and a standard dataset.

Once complete, benchmarking results, such as training time and resource utilization, are available in MLFlow and Grafana for easy tracking. This blueprint enables data-driven infrastructure decisions for your fine-tuning jobs.

## Pre-Filled Samples

| Feature Showcase                                                                                        | Title                                                                                      | Description                                                                                                                        | Blueprint File                                                                                         |
| ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Benchmark LoRA fine-tuning performance using MLCommons methodology with quantized large language models | LoRA fine-tuning of quantitized Llama-2-70B model on A100 node using MLCommons methodology | Deploys LoRA fine-tuning of quantitized Llama-2-70B model on A100 node using MLCommons methodology on BM.GPU.A100.8 with 8 GPU(s). | [mlcommons_lora_finetune_nvidia_sample_recipe.json](mlcommons_lora_finetune_nvidia_sample_recipe.json) |
