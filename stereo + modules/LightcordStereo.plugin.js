/**
 * @name LightcordStereo
 * @description Stereo Plugin for BD
 * @version 1.0.0
 * @author skenzo
 * @authorId 842214916135976981
 * @invite discord.gg/lightcord
 * @website https://www.youtube.com/channel/UCHcAFxh0nWGDVv-TOqxgDRQ
 */

module.exports = class LightcordStereo {
    constructor() {
        this.voiceModule = null;
    }

    start() {
        this.voiceModule = BdApi.Webpack.getModule(m => m.prototype && "setLocalVolume" in m.prototype);
        if (!this.voiceModule) return;
        
        BdApi.Patcher.before("LightcordStereo", this.voiceModule.prototype, "setLocalVolume", (thisObj) => {
            if (!thisObj || !thisObj.conn || !thisObj.conn.setTransportOptions) return;
            
            const conn = thisObj.conn;
            const setTransportOptions = conn.setTransportOptions.bind(conn);
            
            conn.setTransportOptions = (options) => {
                if (!options || typeof options !== "object") return setTransportOptions(options);
                
                Object.assign(options, {
                    audioEncoder: {
                        ...options.audioEncoder,
                        channels: 2,
                        freq: 48000,
                        rate: 512000,
                        pacsize: 960,
                    },
                    packetLossRate: 0,
                    encodingBitRate: 512000,
                    callBitrate: 512000,
                    callMaxBitRate: 512000,
                });
                
                setTransportOptions(options);
            };
        });
    }

    stop() {
        BdApi.Patcher.unpatchAll("LightcordStereo");
    }
};