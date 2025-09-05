version 1.0

task RevertSamTask {
  input {
    File input_bam
    String output_bam_filename
    Int disk_size
    Int memory_in_MiB 
    Boolean restore_hardclips
    Boolean sanitize 
    String stringency 
    String sort_order
    Float max_discard_fraction
  }

  Int java_mem = memory_in_MiB - 1000
  Int max_heap = memory_in_MiB - 500

  command <<<
    java -Xms~{java_mem}m -Xmx~{max_heap}m -jar /usr/picard/picard.jar \
      RevertSam \
      --INPUT ~{input_bam} \
      --OUTPUT ~{output_bam_filename} \
      --VALIDATION_STRINGENCY ~{stringency} \
      --ATTRIBUTE_TO_CLEAR FT \
      --ATTRIBUTE_TO_CLEAR CO \
      --ATTRIBUTE_TO_CLEAR PA \
      --ATTRIBUTE_TO_CLEAR OA \
      --ATTRIBUTE_TO_CLEAR XA \
      --RESTORE_HARDCLIPS ~{restore_hardclips} \
      ~{false="" true="--SANITIZE" sanitize} \
      --MAX_DISCARD_FRACTION ~{max_discard_fraction} \
      --SORT_ORDER ~{sort_order}
  >>>

  runtime {
    docker: "us.gcr.io/broad-gotc-prod/picard-cloud:2.26.10"
    disks: "local-disk " + disk_size + " HDD"
    memory: "~{memory_in_MiB} MiB"
    preemptible: 3
  }

  output {
    File output_bam = output_bam_filename
  }
}

workflow RevertSam {
  input {
    File input_bam
    String output_bam_filename
    Int memory_in_MiB = 3000
    Boolean restore_hardclips = true
    Boolean sanitize = false
    String sort_order = "coordinate"
    String stringency = "LENIENT"
    Float max_discard_fraction = 0.01
  }

  # size(input_bam, "G") returns file size in gigabytes (Float).
  Float input_size_GB = size(input_bam, "G")
  Int disk_size = ceil(input_size_GB * 3.0)

  call RevertSamTask {
    input:
      input_bam            = input_bam,
      output_bam_filename  = output_bam_filename,
      disk_size            = disk_size,
      memory_in_MiB        = memory_in_MiB,
      restore_hardclips    = restore_hardclips,
      sanitize             = sanitize,
      sort_order           = sort_order,
      stringency           = stringency,
      max_discard_fraction = max_discard_fraction
  }

  output {
    File output_bam = RevertSamTask.output_bam
  }
}
