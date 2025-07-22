import { REST, Routes, ApplicationCommandType } from 'discord.js';

const commands = [
  {
    name: "server",
    type: ApplicationCommandType.ChatInput,
    description: "enshrouded server controller",
    options: [
      {
        name: "action",
        type: ApplicationCommandType.Message,
        description: "GCE Instance start/stop",
        required: true,
        choices: [
          { name: "start", value: "start" },
          { name: "stop", value: "stop" },
        ]
      },
    ]
  }
];

const rest = new REST({ version: '10' }).setToken(process.env.TOKEN);

try {
  console.log('Started refreshing application (/) commands.');

  await rest.put(
    Routes.applicationCommands(process.env.CLIENT_ID),
    { body: commands }
  );

  console.log('Successfully reloaded application (/) commands.');
} catch (error) {
  console.error(error);
}
