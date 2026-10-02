process CELLBENDER_MERGE {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b0/b01fb7d6f34ec2485438a09ad1494aa2c897a9b793069f9caef677bcd8d6784d/data':
        'community.wave.seqera.io/library/cellbender_python_webcolors:a114221c4c31ab91' }"

    input:
    tuple val(meta), path(filtered), path(unfiltered), path(cellbender_h5)
    val(output_layer_name)

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path "versions.yml"                    , emit: versions_cellbender, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    output_layer = output_layer_name ?: "cellbender"

    """
    echo ${output_layer}
    """

    template 'merge.py'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}.h5ad"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 -c 'import platform; print(platform.python_version())')
        cellbender: \$(cellbender --version)
    END_VERSIONS
    """
}
