//Example of a metadata driven datafactory pipeline bicep deployment.
//  Creates a foreach loop to iteratively copy the objects.

@description('Name of the pipeline when deployed to data factory.')
param pipelineName string

@description('Folder location to deploy the pipeline.')
param folderPath string = 'metadata-examples'

@description('Source details, one of: https://docs.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories/pipelines?tabs=bicep#copysource-objects')
param source object

@description('Sink details, one of: https://docs.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories/pipelines?tabs=bicep#copysink-objects')
param sink object

@description('Source dataset reference name.')
param sourceDatasetReference string

@description('Sink dataset reference name.')
param sinkDatasetReference string

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
      container: 'examples'
      folder: '/raw/metadataExample/'
      file: 'file1.parquet'
    }
  }
  {
    name: 'Copy table2 to file2'
    source: {
      schema: 'dbo'
      table: 'table2'
    }
    sink: {
      folder: '/raw/metadataExample/'
      file: 'file2.parquet'
    }
  }
]

resource metadataPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
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
                    datasetParams: '@item().sink'
                  }
                }]
              outputs: [{
                type: 'DatasetReference'
                referenceName: sinkDatasetReference
                parameters: {
                  datasetParams: '@item().source'
                }
              }]
            }
          ]
          batchCount: batchCount
          isSequential: false
          items: {
            type: 'Expression'
            value: '@variables(\'objectsArray\')'
          }
        }
      }
    ]
    concurrency: 1
    folder: {
      name: folderPath
    }
    variables: {
      objectsArray: {
        type: 'Array'
        defaultValue: copyMappings
      }
    }
  }
}

output pipelineOutput object = {
  name: pipelineName
}
