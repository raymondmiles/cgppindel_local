#!/usr/bin/env nextflow


params.normal = "/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/normal.bam"
params.docker_image = "/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/cgppindel_image.tar"
params.tumour = "/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/tumour_bamfile_markdup.bam"
params.reference ="/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/reference.fa"
params.simrep ="/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/genes.bed.gz"
params.genes = "/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/simrep.bed.gz"
params.unmatched = "/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/unmatched.gff3.gz"
params.filter = "/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/filter.lst"

// Other Parameters
params.cgppindel_id = "cb44a611a143"
params.assembly = 'GRCh38' //
params.seqtype = 'TG' // 
params.species = "Human"

process setup {
    output:
    path 'input' //, emit: input_dir
    path 'out/cgppindel_output' //, emit: cgppindel_output
    path 'out/output_vcf' //, emit: output_vcf
    path 'out/vcf_index' //, emit: vcf_index
    path 'out/output_log' //, emit: output_log
    path 'out/output_vcf_with_vaf' //, emit: output_vcf_with_vaf
    path 'temp_logs' // , emit: temp_logs

    script:
    """
    mkdir -p input
    mkdir -p out/cgppindel_output
    mkdir -p out/output_vcf
    mkdir -p out/vcf_index
    mkdir -p out/output_log
    mkdir -p out/output_vcf_with_vaf
    mkdir -p temp_logs
    chmod 777 out/cgppindel_output
    """
}

process load_docker_image {
    input:
    file dockerImage_path

    output:
    file 'cgppindel_id'

    script:
    """
    if [ ! -f ${params.docker_image} ]; then
        echo "Docker image file not found: ${params.docker_image}"
        echo | pwd
        exit 1
    fi
    sudo docker load --input ${params.docker_image}
    docker images --format="{{.Repository}} {{.ID}}" | grep "^quay.io" | cut -d' ' -f2 > cgppindel_id
    """
}

process run_cgppindel {

    input:
    val cgppindel_id
    path reference
    path simrep
    path genes
    path unmatched
    val assembly
    val species
    val seqtype
    path filter
    path tumour
    path normal


    publishDir '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_bashexperiment/', mode: 'copy'
    script:
    """
    echo "Running in directory: \$(pwd)"
    echo "Listing files in working directory:"
    ls -lh
    sudo docker run -v "/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/":/"\$(pwd)" \\
    -w "\$(pwd)" $cgppindel_id \\
    pindel.pl \\
    -reference $reference \\
    -simrep $simrep \\
    -genes $genes \\
    -unmatched $unmatched \\
    -assembly $assembly \\
    -species $species \\
    -seqtype $seqtype \\
    -filter $filter \\
    -tumour $tumour \\
    -normal $normal \\
    -outdir out/
    """
}

process annotate_vcf {

    input:
    path vcf_folder

    //output:
    // path 'output_vcf_with_vaf/*.vcf.gz'
    //path 'vcf_index/*.tbi'
    //path 'output_vcf/*.vcf.gz'
    script:
    """
    # Ensure you're in the correct directory
    cd /home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/out/
    
    # Find all .vcf.gz files and store them in a Bash variable
    vcf_files=\$(find . -type f -name "*.vcf.gz" ! -name "*.af.vcf.gz")
    
    # Iterate over the list of VCF files
    for vcf in \${vcf_files}; do
        basename=\$(basename "\$vcf" .vcf.gz)
        output_file="\${basename}.af.vcf.gz"
        if [ ! -e "\$output_file" ]; then
            bcftools view -i 'INFO/LEN > 2' "\$vcf" > "\${basename}.af.vcf"
            bgzip "\${basename}.af.vcf"
        else
            echo "The file \$output_file already exists, skipping compression."
        fi
    done
    """
}




workflow {
    setup()
    //image = file(params.docker_image) // may require absolute path
    //cgppindel_id=load_docker_image(image)
    reference_ch = Channel.fromPath(params.reference)
    simrep_ch = Channel.fromPath(params.simrep)
    genes_ch = Channel.fromPath(params.genes)
    unmatched_ch = Channel.fromPath(params.unmatched)
    filter_ch = Channel.fromPath(params.filter)
    tumour_ch = Channel.fromPath(params.tumour)
    normal_ch = Channel.fromPath(params.normal)
    reference_ch.view()
    run_cgppindel(
        params.cgppindel_id,
        reference_ch,
        simrep_ch,
        genes_ch,
        unmatched_ch,
        params.assembly,
        params.species,
        params.seqtype,
        filter_ch,
        tumour_ch,
        normal_ch
    )
    annotate_vcf(Channel.fromPath("/home/raymondmiles/Desktop/Software_Development/cgppindel_bashexperiment/out/")) 
}
