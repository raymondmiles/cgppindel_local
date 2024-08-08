#!/usr/bin/env nextflow
/*
params.reference = '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/data/GRCh38.no_alt_analysis_set_chr_mask21.fa.fai' //
params.simrep = '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/data/simpleRepeats_sorted.bed.gz' //
params.genes = '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/data/coding_unrestricted_GRCh38_myeloid_v1.0.bed' //
params.unmatched = '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/data/normalPanel.gff3.gz' //
params.assembly = 'GRCh38' //
params.seqtype = 'WGS' // ?
params.filter = '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/data/targetedRules.lst' //
params.tumour = '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/data/tumour_bamfile_markup.bam' //
params.normal = '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/data/TA2_S59_L008_tumor_markdup.bam' //
params.docker_image = '/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/data/cgppindel_image.tar' //
*/

params.reference = 'data/GRCh38.no_alt_analysis_set_chr_mask21.fa.fai'
params.simrep = 'data/simpleRepeats_sorted.bed.gz'
params.genes = 'data/coding_unrestricted_GRCh38_myeloid_v1.0.bed'
params.assembly = 'GRCh38' //
params.seqtype = 'WGS' // ?

params.unmatched = 'data/normalPanel.gff3.gz'
params.filter = 'data/targetedRules.lst'
params.tumour = 'data/tumour_bamfile_markdup.bam'
params.normal = 'data/TA2_S59_L008_tumor_markdup.bam'
params.docker_image = 'cgppindel_image.tar'

params.annots_hdr = 'annots.tsv'
params.tsv_script = 'tsv_file_generator.py'

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

process prepare_reference {
    input:
    path params.reference
    //docker_image
    output:
    path params.reference
    script:
    """
    gzip -d ${params.reference}
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
    file cgppindel_id
    val reference
    val simrep
    val genes
    val unmatched
    val assembly
    val seqtype
    val filter
    val tumour
    val normal

    output:
    path 'out/cgppindel_output/*'

    script:
    """
    cgppindel_id=\$(cat cgppindel_id)
    sudo docker run -v "/home/raymondmiles/Desktop/software_engineering_module/cgppindel_local/":/"\$(pwd)"  -w "\$(pwd)" \${cgppindel_id} \\
    pindel.pl \\
    -reference $reference \\
    -simrep $simrep \\
    -genes $genes \\
    -unmatched $unmatched \\
    -assembly $assembly \\
    -species Human \\
    -seqtype $seqtype \\
    -filter $filter \\
    -tumour $tumour \\
    -normal $normal \\
    -outdir 'data/'
    """
}

process annotate_vcf {
    input:
    path 'out/cgppindel_output/*.vcf.gz'
    path params.annots_hdr
    path params.tsv_script

    output:
    path 'out/output_vcf_with_vaf/*.vcf.gz'
    path 'out/vcf_index/*.tbi'
    path 'out/output_vcf/*.vcf.gz'

    script:
    """
    vcf=\$(find out/cgppindel_output -type f -name "*.vcf.gz")
    basename=\$(basename "\$(basename "\$vcf"params.docker_image
    bcftools view -i 'INFO/LEN > 2' "\${basename}.tmp.af.vcf" > "\${basename}.af.vcf"
    bgzip "\${basename}.af.vcf"
    mv "\${basename}.af.vcf.gz" out/output_vcf_with_vaf
    mv out/cgppindel_output/*.flagged.vcf.gz out/output_vcf
    mv out/cgppindel_output/*.flagged.vcf.gz.tbi out/vcf_index
    """
}

process archive_logs {
    input:
    path 'temp_logs/*.err'
    path 'temp_logs/*.out'

    output:
    path 'out/output_log/logs.tar.gz'

    script:
    """
    tar -zcf out/output_log/logs.tar.gz --remove-files temp_logs
    """
}

workflow {
    setup()
    image = file(params.docker_image) // may require absolute path
    cgppindel_id=load_docker_image(image)

    run_cgppindel(
        cgppindel_id,//file(cgppindel_id),//docker_image_id,
        params.reference,
        params.simrep,
        params.genes,
        params.unmatched,
        params.assembly,
        params.seqtype,
        params.filter,
        params.tumour,
        params.normal
    )
    /*annotate_vcf('out/cgppindel_output/*.vcf.gz',
    params.annots_hdr,
    params.tsv_script)
    archive_logs('temp_logs/*.err','temp_logs/*.out')*/
}

/*
process load_docker_image {
    input:
    path params.docker_image

    output:
    file 'cgppindel_id'

    script:
    """
    sudo docker load --input ${params.docker_image}
    docker images --format="{{.Repository}} {{.ID}}" | grep "^quay.io" | cut -d' ' -f2 > cgppindel_id
    """
}
*/

/*
    sudo docker run -v "\$(pwd)"/data  -w "/out/cgppindel_output" \${cgppindel_id} \\
    pindel.pl \\
    -reference $reference \\
    -simrep $simrep \\
    -genes $genes\\
    -unmatched $unmatched \\
    -assembly assembly \\
    -species Human \\
    -seqtype seqtype \\
    -filter filter \\
    -tumour tumour \\
    -normal normal \\
    -outdir /out/cgppindel_output    
*/