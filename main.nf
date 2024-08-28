nextflow.enable.dsl=2

include { setup } from './modules/CGPPINDEL'
include { run_cgppindel } from './modules/CGPPINDEL'
include { annotate_vcf } from './modules/CGPPINDEL'

// run

workflow{
    setup()
}