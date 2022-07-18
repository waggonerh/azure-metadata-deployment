//Example of a metadata driven datafactory pipeline bicep deployment.
//  Creates a foreach loop to iteratively copy the objects.

@description('Name of the data factory to deploy the pipeline.')
param dataFactoryName string

@description('Name of the pipeline when deployed to data factory.')
param pipelineName string = 'forEach-metadata-pipeline'

@description('Folder location to deploy the pipeline.')
param folderPath string = 'metadata-examples'

@description('Source details, one of: https://docs.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories/pipelines?tabs=bicep#copysource-objects')
param source object = {
  type: 'AzureSqlSource'
}

@description('Sink details, one of: https://docs.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories/pipelines?tabs=bicep#copysink-objects')
param sink object = {
  type: 'AzureBlobFSSink'
}

@description('Source dataset reference name.')
param sourceDatasetReference string = 'AzureSqlTable1'

@description('Sink dataset reference name.')
param sinkDatasetReference string = 'Parquet1'

@description('Number of copy activities to run simultaneously')
param batchCount int = 10

@description('List of objects from the source to copy to the destination.')
param copyMappings array = [
  {
    source: {
      schema: 'dbo'
      table: 'table1'
    }
    sink: {
      fileSystem: 'examples'
      folder: '/raw/metadataExample/'
      file: 'file1.parquet'
    }
  }
  {
    source: {
      schema: 'dbo'
      table: 'table2'
    }
    sink: {
      fileSystem: 'examples'
      folder: '/raw/metadataExample/'
      file: 'file2.parquet'
    }
  }
]

resource deploymentFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

resource metadataPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: deploymentFactory
  name: pipelineName
  properties: {
    activities: [
      {        
        type: 'ForEach'
        name: 'Iterate Copy Mappings'
        typeProperties: {
          activities: [
            {              
              type: 'Copy'
              name: 'Copy Objects'
              typeProperties: {
                source: source
                sink: sink                
              }
              inputs: [{
                  type: 'DatasetReference'
                  referenceName: sourceDatasetReference
                  parameters: {
                    datasetParams: '@item().source'
                  }
                }]
              outputs: [{
                type: 'DatasetReference'
                referenceName: sinkDatasetReference
                parameters: {
                  datasetParams: '@item().sink'
                }
              }]
            }
          ]
          batchCount: batchCount
          isSequential: false
          items: {
            type: 'Expression'
            value: '@variables(\'copyArray\')'
          }
        }
      }
    ]
    concurrency: 1
    folder: {
      name: folderPath
    }
    variables: {
      copyArray: {
        type: 'Array'
        defaultValue: copyMappings
      }
    }
  }
}

output pipelineOutput object = {
  dataFactoryName: dataFactoryName
  pipelineName: pipelineName
}
