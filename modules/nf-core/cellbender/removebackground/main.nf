process CELLBENDER_REMOVEBACKGROUND {
    tag "$meta.id"
    label 'process_medium'
    label 'process_long'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "${ task.accelerator ? 'us.gcr.io/broad-dsde-methods/cellbender:0.4.0' :
    workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
    'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b0/b01fb7d6f34ec2485438a09ad1494aa2c897a9b793069f9caef677bcd8d6784d/data' :
    'community.wave.seqera.io/library/cellbender_python_webcolors:a114221c4c31ab91' }"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("${prefix}.h5")               , emit: h5
    tuple val(meta), path("${prefix}_filtered.h5")      , emit: filtered_h5
    tuple val(meta), path("${prefix}_posterior.h5")     , emit: posterior_h5
    tuple val(meta), path("${prefix}_cell_barcodes.csv"), emit: barcodes
    tuple val(meta), path("${prefix}_metrics.csv")      , emit: metrics
    tuple val(meta), path("${prefix}_report.html")      , emit: report, optional: true
    tuple val(meta), path("${prefix}.pdf")              , emit: pdf
    tuple val(meta), path("${prefix}.log")              , emit: log
    tuple val(meta), path("ckpt.tar.gz")                , emit: checkpoint
    tuple val("${task.process}"), val('cellbender'), eval('cellbender --version'), emit: versions_cellbender, topic: versions

    when:
        task.ext.when == null || task.ext.when
    script:
        prefix = task.ext.prefix ?: "${meta.id}"
        args = task.ext.args ?: ""
        use_gpu = task.accelerator ? "--cuda" : ""
        """
        TMPDIR=. cellbender remove-background \
            ${args} \
            --cpu-threads ${task.cpus} \
            ${use_gpu} \
            --input ${h5ad} \
            --output ${prefix}.h5
        """

    stub:
        prefix = task.ext.prefix ?: "${meta.id}"
        """
        touch "${prefix}.h5"
        touch "${prefix}_filtered.h5"
        touch "${prefix}_posterior.h5"
        touch "${prefix}_cell_barcodes.csv"
        touch "${prefix}_metrics.csv"
        touch "${prefix}_report.html"
        touch "${prefix}.pdf"
        touch "${prefix}.log"
        echo "" | gzip > ckpt.tar.gz
        """
}
