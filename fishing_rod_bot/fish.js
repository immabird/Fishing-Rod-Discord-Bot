const discord = require("discord.js-selfbot");
const aws = require("aws-sdk");
const config = require("./config.json");
const discord_api_token = process.env.DISCORD_API_TOKEN

const dynamodb = new aws.DynamoDB.DocumentClient();
const bot = new discord.Client();
var last_fish_index = -1;

async function handler() {
    await login();
    try {
        await handleAllChannels();
        console.log("Finished handling all channels.");
    } catch (error) {
        console.error("An unhandled exception occured when handling all channels. Error:", error);
    }
    await bot.destroy();
    console.log("Finished. Discord client has been destroyed.");
}

async function login() {
    try {
        await bot.login(discord_api_token);
        console.log("Bot logged in successfully.");
    } catch (error) {
        console.error("Failed to login to Discord. Error:", error);
        process.exit(1);
    }
    return Promise.resolve();
}

async function handleAllChannels() {
    let channel_promises = [];
    for (let i = 0; i < config.servers.length; i++) {
        channel_promises.push(handleChannel(config.servers[i]));
    }
    return Promise.all(channel_promises);
}

async function handleChannel(server) {
    let channel_promises = [];
    if (server.channels.fishfarm) {
        channel_promises.push(farmFish(server.channels.fishfarm));
    }
    if (server.channels.lottery) {
        channel_promises.push(handleLottery(server.channels.lottery));
    }
    return Promise.all(channel_promises);
}

// Get fish

function randInt(a, b) {
    return Math.floor((Math.random() * b) + a);
}

async function farmFish(channel_id) {
    let channel;
    try {
        channel = await bot.channels.fetch(channel_id);
    } catch (error) {
        console.error("Fish farm Error. Failed to fetch channel with ID: %s and Error:", channel_id, error);
    }
    // TODO START
    if (last_fish_index < 0) {
        last_fish_index = randInt(0, config.fishies.length - 1);
    }
    let fish_index = (last_fish_index + 1) % config.fishies.length;
    last_fish_index = fish_index;
    // TODO END
    try {
        await channel.send(config.fishies[fish_index]);
        console.log("Successfully sent fish to channel with ID: %s", channel_id);
    } catch (error) {
        console.error("Failed to send message to channel with ID: %s and Error:", channel_id, error);
    }
    return Promise.resolve();
}

// Lottery

function getTime() {
    // TODO START
    const utc_to_est = -5;
    const time = new Date(Date.now());
    const hours = (time.getHours() + 24 + utc_to_est) % 24;
    const minutes = time.getMinutes();
    return {
        hours: hours,
        minutes: minutes
    };
    // TODO END
}

async function handleLottery(channel_id) {
    let channel;
    try {
        channel = await bot.channels.fetch(channel_id);
    } catch (error) {
        console.error("Lottery Error. Failed to fetch channel with ID: %s and Error:", channel_id, error);
        return Promise.resolve();
    }
    const time = getTime();
    if (time.hours == 9 && time.minutes <= 1) {
        await startLottery(channel);
    } else if (time.hours == 18 && time.minutes <= 1) {
        await finishLottery(channel);
    }
    // await finishLottery(channel);
    return Promise.resolve();
}

async function write(channel_id, lottery_in_progress, lottery_message_id) {
    var params = {
        TableName: "Fishing-Rod-Bot-Data",
        Key: {
            "ChannelId": channel_id
        },
        UpdateExpression: "set LotteryInProgress = :lottery_in_progress, LotteryMessageId = :lottery_message_id",
        ExpressionAttributeValues: {
            ":lottery_in_progress": lottery_in_progress,
            ":lottery_message_id": lottery_message_id
        },
        ReturnValues: "ALL_OLD"
    };
    return new Promise((resolve, reject) => {
        dynamodb.update(params, (error, data) => {
            if (error) {
                reject(error);
            } else {
                resolve(data);
            }
        });
    });
}

async function read(channel_id) {
    var params = {
        TableName: "Fishing-Rod-Bot-Data",
        Key: {
            "ChannelId": channel_id
        }
    };
    return new Promise((resolve, reject) => {
        dynamodb.get(params, (error, data) => {
            if (error) {
                reject(error);
            } else {
                resolve(data.Item);
            }
        });
    });
}

async function startLottery(channel) {
    const start_lottery_text = "To enter the lottery drawing react to this message with an emoji from the nature category in the emoji list.";
    const lottery_message = await channel.send(start_lottery_text);
    await write(channel.id, true, lottery_message.id);
}

async function finishLottery(channel) {
    const data = await read(channel.id);//write(channel.id, false, null);
    console.log("Data: " + JSON.stringify(data));
    console.log("progress: " + data.LotteryInProgress);
    if (data.LotteryInProgress) {
        console.log("test1");
        let lottery_message;
        try {
            lottery_message = await channel.messages.fetch(data.LotteryMessageId);
        } catch (error) {
            console.error("Lottery Error. Failed to fetch lottery message with ID: %s and Error:", data.LotteryMessageId, error);
            //await channel.send("It seems there has been an issue with the lottery today.");
            return Promise.resolve();
        }
        let reactions = lottery_message.reactions;
        console.log("test");
        console.log("Reactions: " + reactions);
        const username = "";
        const finish_lottery_text = "The winner of todays lottery is..." + username;
    }
    return Promise.resolve();
}

async function sellFish(channel_id) {
    const sell_command = "l.sell all";
    return messageChannel(channel_id, sell_command);
}

async function giveMoney(channel_id, username) {
    const give_command = "l.give all @" + username;
    return messageChannel(channel_id, give_command);
}

// export handler

exports.handler = handler;
