import functions from '@google-cloud/functions-framework';
import {
  InteractionResponseType,
  InteractionType,
  verifyKey,
} from 'discord-interactions';
import { InstancesClient } from '@google-cloud/compute';

const CLIENT_PUBLIC_KEY = process.env.CLIENT_PUBLIC_KEY;
const PROJECT_ID = process.env.PROJECT_ID
const ZONE = process.env.ZONE
const INSTANCE = process.env.INSTANCE

functions.http('invoke', async (req, res) => {
  // Verify the request
  const signature = req.get('X-Signature-Ed25519');
  const timestamp = req.get('X-Signature-Timestamp');
  const isValidRequest = await verifyKey(
    req.rawBody,
    signature,
    timestamp,
    CLIENT_PUBLIC_KEY,
  );
  if (!isValidRequest) {
    return res.status(401).end('Bad request signature');
  }

  const client = new InstancesClient();
  const request = {
    project: PROJECT_ID,
    zone: ZONE,
    instance: INSTANCE,
  };

  // Handle the payload
  const interaction = req.body;

  if (interaction && interaction.type === InteractionType.APPLICATION_COMMAND) {
    const command = interaction.data.options?.[0]?.value; // "start" or "stop"
     res.send({
      type: InteractionResponseType.CHANNEL_MESSAGE_WITH_SOURCE,
      data: {
        content: `Your request to ${command} the server has been received.`,
      },
    });

    try {
      switch (command) {
        case 'start':
          await client.start(request)
          break;
        case 'stop':
          await client.stop(request)
          break;
      }
    } catch (err) {
      console.log(`Error while executing command "${command}": ${err.message}`);
    }
  } else {
    res.send({
      type: InteractionResponseType.PONG,
    });
  }
});
