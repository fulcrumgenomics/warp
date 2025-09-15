version 1.0

import "../../tasks/broad/Utilities.wdl" as Utils
import "../../tasks/broad/Qc.wdl" as QC

workflow BamToCram {

  input {
    File input_bam
    File ref_fasta
    File ref_fasta_index
    File ref_dict
    File duplication_metrics
    File chimerism_metrics
    String base_file_name
    Int agg_preemptible_tries
  }


  # ValidateSamFile runs out of memory in mate validation on crazy edge case data, so we want to skip the mate validation
  # in those cases.  These values set the thresholds for what is considered outside the normal realm of "reasonable" data.
  Float max_duplication_in_reasonable_sample = 0.30
  Float max_chimerism_in_reasonable_sample = 0.15

  # Convert the final merged recalibrated BAM file to CRAM format
  call Utils.ConvertToCram as ConvertToCram {
    input:
      input_bam = input_bam,
      ref_fasta = ref_fasta,
      ref_fasta_index = ref_fasta_index,
      output_basename = base_file_name,
      preemptible_tries = agg_preemptible_tries
  }

  # Check whether the data has massively high duplication or chimerism rates
  call QC.CheckPreValidation as CheckPreValidation {
    input:
      duplication_metrics = duplication_metrics,
      chimerism_metrics = chimerism_metrics,
      max_duplication_in_reasonable_sample = max_duplication_in_reasonable_sample,
      max_chimerism_in_reasonable_sample = max_chimerism_in_reasonable_sample,
      preemptible_tries = agg_preemptible_tries
 }


  output {
     File output_cram = ConvertToCram.output_cram
     File output_cram_index = ConvertToCram.output_cram_index
     File output_cram_md5 = ConvertToCram.output_cram_md5
  }
  meta {
    allowNestedInputs: true
  }
}

