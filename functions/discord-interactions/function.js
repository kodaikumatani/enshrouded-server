import functions from '@google-cloud/functions-framework';
import {
  InteractionResponseType,
  InteractionType,
  verifyKey,
} from 'discord-interactions';
import { PubSub } from '@google-cloud/pubsub';

const clientPublicKey = process.env.CLIENT_PUBLIC_KEY;
const projectId = process.env.PROJECT_ID
const topicName = process.env.TOPIC_NAME
const pubsub = new PubSub({projectId});

functions.http('discordInteractions', async (req, res) => {
  // Verify the request
  const signature = req.get('X-Signature-Ed25519');
  const timestamp = req.get('X-Signature-Timestamp');
  const isValidRequest = await verifyKey(
    req.rawBody,
    signature,
    timestamp,
    clientPublicKey,
  );
  if (!isValidRequest) {
    return res.status(401).end('Bad request signature');
  }

  // Handle the payload
  const interaction = req.body;

  if (interaction && interaction.type === InteractionType.APPLICATION_COMMAND) {
    const command = interaction.data.options?.[0]?.value; // "start" or "stop"

    try {
      await pubsub.topic(topicName).publishMessage({data: Buffer.from(command)})
    } catch (error) {
      console.error(error);
      return res.status(500).end('Faild to push message');
    }

    res.send({
      type: InteractionResponseType.CHANNEL_MESSAGE_WITH_SOURCE,
      data: {
        content: `Your request to ${command} the server has been received.`,
      },
    });
  } else {
    res.send({
      type: InteractionResponseType.PONG,
    });
  }
});
