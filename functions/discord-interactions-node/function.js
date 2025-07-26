import functions from '@google-cloud/functions-framework';
import {
  InteractionResponseType,
  InteractionType,
  verifyKey,
} from 'discord-interactions';
import { PubSub } from '@google-cloud/pubsub';

const CLIENT_PUBLIC_KEY = process.env.CLIENT_PUBLIC_KEY;
const PROJECT_ID = process.env.PROJECT_ID
const TOPIC_NAME = process.env.TOPIC_NAME
const pubsub = new PubSub({PROJECT_ID});

functions.http('discordInteractions', async (req, res) => {
  // Verify the request
  const signature = req.get('X-Signature-Ed25519');
  const timestamp = req.get('X-Signature-Timestamp');
  const isValidRequest = await verifyKey(
    req.rawBody,
    signature,
    timestamp,
    CLIENT_PUBLIC_KEY,
  );
  // if (!isValidRequest) {
  //   return res.status(401).end('Bad request signature');
  // }

  await pubsub.topic(TOPIC_NAME).publishMessage({data: Buffer.from('Test message!')});

  res.send({
    type: InteractionResponseType.CHANNEL_MESSAGE_WITH_SOURCE,
    data: {
      content: `Your request to the server has been received.`,
    },
  })
});

// functions.http('discordInteractions', async (req, res) => {
//   // Verify the request
//   const signature = req.get('X-Signature-Ed25519');
//   const timestamp = req.get('X-Signature-Timestamp');
//   const isValidRequest = await verifyKey(
//     req.rawBody,
//     signature,
//     timestamp,
//     CLIENT_PUBLIC_KEY,
//   );
//   if (!isValidRequest) {
//     return res.status(401).end('Bad request signature');
//   }

//   // Handle the payload
//   const interaction = req.body;

//   if (interaction && interaction.type === InteractionType.APPLICATION_COMMAND) {
//     const command = interaction.data.options?.[0]?.value; // "start" or "stop"
//     await pubsub.topic(TOPIC_NAME).publishMessage({data: Buffer.from(command)})

//     res.send({
//       type: InteractionResponseType.CHANNEL_MESSAGE_WITH_SOURCE,
//       data: {
//         content: `Your request to ${command} the server has been received.`,
//       },
//     });
//   } else {
//     res.send({
//       type: InteractionResponseType.PONG,
//     });
//   }
// });
