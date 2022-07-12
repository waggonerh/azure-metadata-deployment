//Example of a metadata driven datafactory pipeline bicep deployment.
//  Creates a fore each loop to iteratively copy the objects.
//
//  Warning: Dataset references expect a parameter 'objectName'. Modify
//    in code below to match your needs.

@description('Name of the pipeline when deployed to data factory.')
param pipelineName string

@description('Folder location to deploy the pipeline.')
param folderPath string = 'metadata-examples'

@description('Source details, one of: https://docs.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories/pipelines?tabs=bicep#copysource-objects')
param source object

@description('Sink details, one of: https://docs.microsoft.com/en-us/azure/templates/microsoft.datafactory/factories/pipelines?tabs=bicep#copysink-objects')
param sink object

@description('Source dataset reference name.')
param sourceDatasetReferenceName string

@description('Sink dataset reference name.')
param sinkDatasetReferenceName string

@description('Number of copy activities to run simultaneously')
param batchCount int = 10

@description('List of objects from the source to copy to the destination.')
param objects array = [
  {
    sourceName: 'table1'
    sinkName: 'file1'
  }
]

resource metadataPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: pipelineName
  properties: {
    activities: [
      {        
        type: 'ForEach'
        name: 'Iterate Objects'
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
                  referenceName: sourceDatasetReferenceName
                  parameters: {
                    objectName: '@item().sourceName'
                  }
                }]
              outputs: [{
                type: 'DatasetReference'
                referenceName: sinkDatasetReferenceName
                parameters: {
                  objectName: '@item().sinkName'
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
        defaultValue: objects
      }
    }
  }
}

output pipelineOutput object = {
  name: pipelineName
}
