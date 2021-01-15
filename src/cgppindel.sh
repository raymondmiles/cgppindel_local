#!/bin/bash
# cgppindel 1.0.0

set -e -x -o pipefail


main() {

    echo "Value of reference: '$reference'"
    echo "Value of simrep: '$simrep'"
    echo "Value of genes: '$genes'"
    echo "Value of unmatched: '$unmatched'"
    echo "Value of assembly: '$assembly'"
    echo "Value of species: '$species'"
    echo "Value of seqtype: '$seqtype'"
    echo "Value of filter: '$filter'"
    echo "Value of tumour: '$tumour'"
    echo "Value of normal: '$normal'"
    
    mkdir input
    mkdir -p out/cgppindel_output
    chmod 777 out/cgpindel_output

    dx-download-all-inputs
    find ~/in -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/input

    # Unzip fasta reference
    gzip -d ~/input/$reference_name


    # add dnanexus user to docker group & start docker daemon
    sudo usermod -a -G docker dnanexus
    newgrp docker
    sudo systemctl start docker

    # load local container & get id
    sudo docker load --input ~/input/$docker_image_name 
    cgppindel_id=$(docker images --format="{{.Repository}} {{.ID}}" | grep "^quay.io" | cut -d' ' -f2) 
   

    sudo docker run -v `pwd`:/data -w "/data/out/cgppindel_output" $cgppindel_id \
    pindel.pl \
    -reference /data/input/${reference_prefix}fa \
    -simrep /data/input/$simrep_name \
    -genes /data/input/$genes_name \
    -unmatched /data/input/$unmatched_name \
    -assembly $assembly \
    -species Human \
    -seqtype $seqtype \
    -filter /data/input/$filter_name \
    -tumour /data/input/$tumour_name \
    -normal /data/input/$normal_name \
    -outdir /data/out/cgpindel_output



    # upload output files
    dx-upload-all-outputs

    echo "Upload Complete"
}
