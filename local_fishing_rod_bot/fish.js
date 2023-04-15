const discord = require("discord.js-selfbot");
const fs = require("fs");
const config = JSON.parse(fs.readFileSync("config.json"));
const interval = 16000;

var bot = new discord.Client();

run();

async function run() {
    console.log("Logging in.");
    console.log("token: " + config.token);
    await bot.login(config.token);
    await sleep(interval);
    console.log("Successfully logged in.");
    for (let i = 0; i < config.channel_ids.length; i++) {
        fishSpam(config.channel_ids[i]);
    }
}

async function fishSpam(channel_id) {
    console.log(channel_id);
    let channel = await bot.channels.fetch(channel_id);
    console.log("Channel b4 loop: " + channel);
    for (let i = randInt(0, config.fishies.length - 1); true; i = (i + 1) % config.fishies.length) {
        console.log("Channel after loop: " + channel);
        await channel.send("Local: " + config.fishies[i]);
        console.log("Sent message to channel with ID: %s", channel_id);
        await sleep(interval);
    }
}

function randInt(a, b) {
    return Math.floor((Math.random() * b) + a);
}

async function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
}
