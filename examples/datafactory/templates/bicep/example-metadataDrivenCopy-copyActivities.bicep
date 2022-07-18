//Example of a metadata driven datafactory pipeline bicep deployment.
//  Creates an activity for every object to copy.
//
//  Warning: If the maximum number of activities (40) is exceeded, the process
//    is split into worker pipelines and a single control pipeline is
//    created. This allows for a maximum of 160 objects before breakage.

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

@description('List of objects from the source to copy to the destination.')
param copyMappings array = [
  {
    name: 'Copy table1 to file1'
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

var objectCount = length(copyMappings)
var maxActivities = 40

// Basic formula for Ceiling function
// Maximum of 40 activities per pipeline, this will determine the total pipelines required to deploy.
var requiredPipelines = objectCount / maxActivities + (1 - ((objectCount % maxActivities) / maxActivities))

var workerPipelines = [for i in range(1, requiredPipelines): {
  name: (requiredPipelines == 1) ? pipelineName : '${pipelineName}-${i}'
}]


resource workerPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = [for workerPipeline in workerPipelines: {
  name: workerPipeline.name
  properties: {
    activities: [for copyMapping in copyMappings: {
      type: 'Copy'
      name: copyMapping.name
      typeProperties: {
        source: source
        sink: sink
      }
      inputs: [{
          type: 'DatasetReference'
          referenceName: sourceDatasetReference
          parameters: copyMapping.source
        }]
      outputs: [{
        type: 'DatasetReference'
        referenceName: sinkDatasetReference
        parameters: copyMapping.sink
      }]
    }]
    concurrency: 1
    folder: {
      name: folderPath
    } 
  }
}]

resource controlPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = if(requiredPipelines > 1) {
  name: pipelineName
  dependsOn: workerPipeline
  properties: {
    activities: [for (workerPipeline, i) in workerPipelines: {
      dependsOn: (i > 0) ? [ {
        activity: workerPipelines[i-1]
        dependencyConditions: [
          'Succeeded'
        ]
      }] : null
      name: workerPipeline.name
      type: 'ExecutePipeline'
      typeProperties: {
        pipeline: {
          type: 'PipelineReference'
          name: workerPipeline.name
          referenceName: workerPipeline.name
        }
        waitOnCompletion: true        
      }
    }]
  }
}

output pipelineOutput object = {
  name: pipelineName
  workerPipelines: (requiredPipelines > 1) ? workerPipelines : null
}
