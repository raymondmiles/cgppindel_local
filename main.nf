#!/usr/bin/env nextflow

// Define the workflow process
process sayHello {

    output:
        stdout

    """
    echo 'Hello World!'
    """
}

// Run the process
workflow {
    // Call the process
    sayHello()
}
