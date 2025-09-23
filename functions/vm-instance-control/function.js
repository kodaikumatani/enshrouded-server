import functions from '@google-cloud/functions-framework';
import { InstancesClient, ZoneOperationsClient } from '@google-cloud/compute'

const projectId = process.env.PROJECT_ID
const zone = process.env.ZONE
const instanceName = process.env.INSTANCE_NAME
const instancesClient = new InstancesClient();
const operationsClient = new ZoneOperationsClient();

functions.cloudEvent('helloPubSub', async cloudEvent => {
  // The Pub/Sub message is passed as the CloudEvent's data payload.
  const command = Buffer.from(cloudEvent.data.message.data, 'base64').toString()

  let message = '';

  switch (command) {
    case "start": {
      const [startResponse] = await instancesClient.start({
        project: projectId,
        zone,
        instance: instanceName,
      });
      let startOperation = startResponse.latestResponse;

      // Wait for the operation to complete.
      while (startOperation.status !== 'DONE') {
        [startOperation] = await operationsClient.wait({
          operation: startOperation.name,
          project: projectId,
          zone: startOperation.zone.split('/').pop(),
        });
      }
      message = 'Instance has been successfully started.';
      console.log('Instance started.');
      break;
    }
    case "stop": {
      const [stopResponse] = await instancesClient.stop({
        project: projectId,
        zone,
        instance: instanceName,
      });
      let stopOperation = stopResponse.latestResponse;

      // Wait for the operation to complete.
      while (stopOperation.status !== 'DONE') {
        [stopOperation] = await operationsClient.wait({
          operation: stopOperation.name,
          project: projectId,
          zone: stopOperation.zone.split('/').pop(),
        });
      }
      message = 'Instance has been successfully stopped.';
      console.log('Instance stopped.');
      break;
    }
    default:
      console.error("unknown command");
      return;
  }


});
