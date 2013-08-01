/**
    jQuery Flash Preflight to check Flash settings before engaging a heavier Flash application
    Copyright (c) 2013, Edoceo, Inc (code@edoceo.com)

    Heavily influneced by:
        jquery-webcam by Robert Eisele
        http://www.xarg.org/project/jquery-webcam-plugin/

        jQuery AS3 Webcam by Sergey Shilko
        @see https://github.com/sshilko/jQuery-AS3-Webcam

*/

/* SWF external interface:
 micFind
 micList - Array of microphone names

 camFind
 camList - Array of camera names

 * webcam.save() - get base64 encoded JPEG image
 * webcam.setCamera(i) - set camera, camera index retrieved with camList
 * webcam.getResolution() - get camera resolution actually applied
*/

/* External triggers on events:
 * webcam.isClientReady() - you respond to SWF with true (by default) meaning javascript is ready to accept callbacks
 * webcam.cameraConnected() - camera connected callback from SWF
 * webcam.noCameraFound() - SWF response that it cannot find any suitable camera
 * webcam.cameraEnabled() - SWF response when camera tracking is enabled (this is called multiple times, use isCameraEnabled flag)
 * webcam.cameraDisabled()- SWF response, user denied usage of camera
 * webcam.swfApiFail()    - Javascript failed to make call to SWF
 * webcam.debug()         - debug callback used from SWF and can be used from javascript side too
 * */

// @edoceo
// http://livedocs.adobe.com/flex/3/html/help.html?content=Working_with_Sound_19.html
// http://thinkdiff.net/mixed/getting-external-parameters-in-actionscript-3/
// Draw Line then Fade it out for Mic Check: http://joshshard.com/blog/?p=19
// http://blog.iconara.net/2007/01/20/abusing-the-externalinterface/
// http://www.stoimen.com/blog/2009/10/29/passing-objects-with-externalinterface-from-js-to-flex/
// http://www.adobe.com/devnet/flash/articles/flcs5_features_microphone_event.html
// https://code.google.com/p/flash-mirror/
// http://www.actionscript.org/forums/showthread.php3?t=195531
// http://stackoverflow.com/questions/574627/how-to-flip-flash-media-video
// http://stackoverflow.com/questions/5722561/as3-render-text-straight-to-sprite-graphics


package {

import flash.system.Security;
import flash.system.SecurityPanel;

import flash.external.ExternalInterface;

import flash.media.Camera;
import flash.media.Microphone;
import flash.media.Video;
import flash.events.*;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display.StageQuality;

import flash.text.TextField;

import flash.utils.ByteArray;
import flash.utils.Timer;

import com.adobe.images.JPGEncoder;
import Base64;

public class Preflight extends Sprite {

    private var opt_mic_bg:uint = 0x111111;
    private var opt_mic_fg:uint = 0x23cc19;
    private var opt_mic_xy:Array = [ 0, 240 ];
    // private var opt_mic_wh:Array = [ ];
    private var opt_mic_lo:int = 30; // 1-100 of Volume Level

    private var opt_cam_bg:uint = 0x222222;
    private var opt_cam_fg:uint = 0xeeeeee;
    private var opt_cam_xy:Array = [ 0, 0 ];
    //private var opt_cam_wh:Array = [ ];

    private var camera:Camera  = null;
    private var mic:Microphone = null;
    private var video:Video    = null;
    private var bmd:BitmapData = null;

    private var camW:int = 320;
    private var camH:int = 240;

    private var camBandwidth:int = 0; // Specifies the maximum amount of bandwidth that the current outgoing video feed can use, in bytes per second. To specify that Flash Player video can use as much bandwidth as needed to maintain the value of quality , pass 0 for bandwidth . The default value is 16384.
    private var camQuality:int = 100; // this value is 0-100 with 1 being the lowest quality. Pass 0 if you want the quality to vary to keep better framerates
    private var camFrameRate:int = 14;

    // private var camResolution:Array;

    // Drawing Tools for Mic Stream
    private var nWidth:Number = stage.stageWidth;
    private var nPitch:int = 0;
    private var nX:int = 0;
    private var nY:int = 0;
    private var micAudioLevel:int = 0;

    private var rectB:Shape;
    
    private var objCallback:String = 'preflight';

    public function Preflight():void {

        ExternalInterface.call("console.log","init (w" + Math.floor(stage.stageWidth) + ",h" + Math.floor(stage.stageHeight) + ")");

        flash.system.Security.allowDomain("*");
        stage.scaleMode = StageScaleMode.EXACT_FIT;
        stage.quality = StageQuality.BEST;
        // stage.align = ""; // empty string is absolute center

        readParameters();
        drawBoxes();

        // Connect External Routines
        // General
        ExternalInterface.addCallback("getInfo", this.getInfo);

        // Camera Stuff
        ExternalInterface.addCallback("camFind", this.camFind);
        ExternalInterface.addCallback("camList", this.camList);
        // ExternalInterface.addCallback("camPick", this.camPick);

        // Microphone Stuff
        ExternalInterface.addCallback("micFind", this.micFind);
        ExternalInterface.addCallback("micList", this.micList);
        // ExternalInterface.addCallback("micPick", this.micPick);

        // ExternalInterface.addCallback("save", save);
        // ExternalInterface.addCallback("setCamera", setCamera);
        // ExternalInterface.addCallback("getResolution", getResolution);
        // ExternalInterface.addCallback("getCameraList", getCameraList);

        this.camW = stage.stageWidth;
        // this.camW = stage.stageWidth;

        micFind();
        camFind();

    }

    /**

    */
    public function getInfo():Object
    {
        ExternalInterface.call("console.log","getInfo()");

        var ret:Object = new Object;

        ret.w_ask = this.loaderInfo.parameters["resolutionWidth"];
        ret.w_stage = stage.stageWidth;
        ret.h_ask = this.loaderInfo.parameters["resolutionHeight"];
        ret.h_stage = stage.stageHeight;

        ret.cam_name = camera.name;
        ret.cam_w = camera.width;
        ret.cam_h = camera.height;

        ret.mic = this.micFind();

        ret.opt = this.loaderInfo.parameters;

//         var resolutionWidth:Number = this.loaderInfo.parameters["resolutionWidth"];
//         var videoWidth:Number      = Math.floor(resolutionWidth);
//
//         var resolutionHeight:Number = this.loaderInfo.parameters["resolutionHeight"];
//         var videoHeight:Number      = Math.floor(resolutionHeight);
//
//         var serverWidth:Number  = Math.floor(stage.stageWidth);
//         var serverHeight:Number = Math.floor(stage.stageHeight);
//
//         ExternalInterface.call("pf.debug","resolutionW",Math.max(videoWidth, serverWidth));
//         ExternalInterface.call("pg.debug","resolutionH",Math.max(videoHeight, serverHeight));
//
        // var result:Array = [Math.max(videoWidth, serverWidth), Math.max(videoHeight, serverHeight)];
        // var result:Array = [ stage.stageWidth, stage.stageHeight ];
        // var result:Array = [ 320, 240 ];
        // return result;

        return ret;
    }


    public function camFind():Object
    {
        ExternalInterface.call("console.log","camFind()");

        camera = Camera.getCamera();
        if (null == camera) {
            ExternalInterface.call(this.objCallback + ".onCamNotFound");
            return null;
        }

        if (camera.muted) {
            Security.showSettings(SecurityPanel.CAMERA);
        }

        if (ExternalInterface.available) {

            camera = Camera.getCamera('0');
            // camResolution = getCameraResolution();
            setupCamera(camera);
            setVideoCamera(camera);

            /**
             * Dont use stage.width & stage.height because result image will be stretched
             */
            bmd = new BitmapData(camW, camH);

            try {
                var containerReady:Boolean = isContainerReady();
                if (containerReady) {
                    // setupCallbacks();
                }  else {
                    // var readyTimer:Timer = new Timer(250);
                    // readyTimer.addEventListener(TimerEvent.TIMER, timerHandler);
                    // readyTimer.start();
                }
            } catch (err:Error) { } finally { }
        } else {

        }

        ExternalInterface.call(this.objCallback + ".onCamFound");

        var ret:Object = new Object;
        ret.name = camera.name;

        return ret;
    }

    private function setupCamera(useCamera:Camera):void {

        useCamera.setMode(this.camW,this.camH,camFrameRate);

        // camResolution[0] = useCamera.width;
        // camResolution[1] = useCamera.height;
        camFrameRate     = useCamera.fps;

        useCamera.setQuality(camBandwidth, camQuality);
        useCamera.addEventListener(StatusEvent.STATUS, statusHandler);
        useCamera.setMotionLevel(100); //disable motion detection
    }

    private function setVideoCamera(useCamera:Camera):void {
            var doSmoothing:Boolean = this.loaderInfo.parameters["smoothing"];
            var doDeblocking:Number = this.loaderInfo.parameters["deblocking"];

            video = new Video(this.camW,this.camH); // camResolution[0],camResolution[1]);
            video.smoothing  = true;
            video.deblocking = 0; /// doDeblocking;
            // video.scaleX = video.scaleY = -1;
            // video.x = video.width; video.scaleX *= -1;
            video.scaleX = -1; video.x = video.width + video.x; // mirror
            video.attachCamera(useCamera);
            addChild(video);
    }

    private function statusHandler(event:StatusEvent):void {
            if (event.code == "Camera.Unmuted") {
                camera.removeEventListener(StatusEvent.STATUS, statusHandler);
                // extCall('cameraEnabled');
            } else {
                // extCall('cameraDisabled');
            }
    }

    //private function extCall(func:String):Boolean {
    //        var target:String = this.loaderInfo.parameters["callTarget"];
    //        // ExternalInterface.call("console.log",target + "." + func);
    //        return ExternalInterface.call(this.objCallback + "." + func);
    //}

    private function isContainerReady():Boolean
    {
        var result:Boolean = ExternalInterface.call(this.objCallback + ".onReady");
        return result;
    }

    // private function setupCallbacks():void {
    // 
    //         extCall('cameraConnected');
    //         /* when we have pernament accept policy --> */
    //         if (!camera.muted) {
    //             extCall('cameraEnabled');
    //         } else {
    //             Security.showSettings(SecurityPanel.PRIVACY);
    //         }
    //         /* when we have pernament accept policy <-- */
    // }

//    private function timerHandler(event:TimerEvent):void {
//            var isReady:Boolean = isContainerReady();
//            if (isReady) {
//                Timer(event.target).stop();
//                // setupCallbacks();
//            }
//        }

        /**
            Returns actual resolution used by camera
        */
        public function getResolution():Array {
             // var res:Array = [camResolution[0], camResolution[1]];
             var res:Array = [this.camW, this.camH];
             return res;
        }

        /**
            @return a list of Camera Names
        */
        public function camList():Array {
            var list:Array = Camera.names;
            return list;
        }

        public function setCamera(id:String):Boolean {
            var newcam:Camera = Camera.getCamera(id.toString());
            if (newcam) {
                setupCamera(newcam);
                setVideoCamera(newcam);
                camera = newcam;
                return true;
            }
            return false;
        }

        public function save():String {
            bmd.draw(video);
            video.attachCamera(null); //this stops video stream, video will pause on last frame (like a preview)
            var quality:Number = 100;
            var byteArray:ByteArray = new JPGEncoder(quality).encode(bmd);
            var string:String = Base64.encodeByteArray(byteArray);
            return string;
        }

    /**
        Finds a Microphone
    */
    public function micFind():Object
    {
        ExternalInterface.call("console.log","micFind()");

        mic = Microphone.getMicrophone();
        mic.setLoopBack(true);
        // mic.setSilenceLevel(10, 1000);
        mic.setUseEchoSuppression(true);
        mic.addEventListener(ActivityEvent.ACTIVITY, this.onMicActivity);
        mic.addEventListener(StatusEvent.STATUS, this.onMicStatus);
        mic.addEventListener(SampleDataEvent.SAMPLE_DATA, this.drawMicData);

        // var micDetails:String = "Sound input device name: " + mic.name + '\n';
        // micDetails += "Gain: " + mic.gain + '\n';
        // micDetails += "Rate: " + mic.rate + " kHz" + '\n';
        // micDetails += "Muted: " + mic.muted + '\n';
        // micDetails += "Silence level: " + mic.silenceLevel + '\n';
        // micDetails += "Silence timeout: " + mic.silenceTimeout + '\n';
        // micDetails += "Echo suppression: " + mic.useEchoSuppression + '\n';
        // trace(micDetails);
        // var json : String = "{a: 1, b: 'hello world', c: [1, 3, 4, 5]}";

        var ret:Object = new Object; // = ExternalInterface.call("function( ) { return " + json + ";"}");
        ret.name = mic.name;
        ret.gain = mic.gain;
        ret.rate = mic.rate;
        ret.mute = mic.muted;

        ExternalInterface.call(this.objCallback + ".onMicFound",ret);

        return ret;
    }

    /**
        Return a List of Microphones
    */
    public function micList():Array {
        var list:Array = Microphone.names;
        return list;
    }

    /**
        Call Out to External
    */
    private function onMicActivity(e:ActivityEvent):void
    {
        // ExternalInterface.call("pf.debug","info","onMicActivity");
        if (e.activating) {
            //
        } else {
            this.micDrawLine();
        }

        // Callout
        ExternalInterface.call(this.objCallback + ".onMicActivity",e.activating,mic.activityLevel);
    }

    /**
        Call Out to External
    */
    private function onMicStatus(e:StatusEvent):void
    {
        ExternalInterface.call("console.log","preflight.onMicStatus()");
        // ExternalInterface.call("pf.onMicStatus",event); //  + event.level + ", code=" + event.code);
    }

    /**
        Draw the Audio Stream
    */
    private function drawMicData(event:SampleDataEvent):void {
        // ExternalInterface.call("pf.debug","info","drawMicData");
        // var myData:ByteArray = eventObject.data;
        var myData:ByteArray = event.data;
        var nScale:Number = 64;
        var nCenter:Number = 240+32; // stage.stageHeight; //  - 2;

        rectB.graphics.clear();
        rectB.graphics.beginFill(this.opt_mic_bg);
        rectB.graphics.drawRect(this.opt_mic_xy[0],this.opt_mic_xy[1],Math.floor(stage.stageWidth),64);
        rectB.graphics.endFill();

        rectB.graphics.lineStyle(0, this.opt_mic_fg);
        rectB.graphics.moveTo(0, nCenter); // Math.floor(stage.stageHeight) - (nScale / 2)
        // myGraphics.z = 1000;

        var nPitch:Number = nWidth / myData.length;
        while (myData.bytesAvailable > 0)
        {
            var nX:Number = myData.position * nPitch;
            var nY:Number = myData.readFloat() * nScale + nCenter;
            rectB.graphics.lineTo(nX, nY);
        }

        if (this.mic.activityLevel > this.opt_mic_lo) {
            // ExternalInterface.call("console.log","drawMicData(Loud+2)");
            ExternalInterface.call(this.objCallback + ".onMicCheck",Math.floor(this.mic.activityLevel));
        }
    }

    /**
        Draws the Default State, dark rectangle with green.
    */
    private function micDrawLine():void
    {
        rectB.graphics.clear();
        rectB.graphics.beginFill(this.opt_mic_bg);
        rectB.graphics.drawRect(this.opt_mic_xy[0],this.opt_mic_xy[1],Math.floor(stage.stageWidth),64);
        rectB.graphics.endFill();
        rectB.graphics.lineStyle(0, this.opt_mic_fg);
        rectB.graphics.moveTo(0, 240 + 32); // Math.floor(stage.stageHeight) - (nScale / 2)
        rectB.graphics.lineTo(stage.stageWidth, 240 + 32);
    }

    /**
        Draw Containers for our Video and our Sound Meter
    */
    private function drawBoxes():void
    {
        // Add the Video Layer
//            var rectA:Shape = new Shape;
//            rectA.graphics.beginFill(this.opt_cam_bg);
//            rectA.graphics.drawRect(this.opt_cam_xy[0],this.opt_cam_xy[1],Math.floor(stage.stageWidth),240);
//            rectA.graphics.endFill();
//            addChild(rectA);

        // Audio Layer
//            var audioLayer:Sprite = new Sprite;

        this.rectB = new Shape;
        this.micDrawLine();
//            audioLayer.addChild(rectB);
//
//            // Text Label
//            var textA:TextField = new TextField;
//            textA.text = "Audio Signal";
//            var textI:BitmapData = new BitmapData(textA.width, textA.height, true, 0x000000ff);
//            textI.draw(textA);
//            var textS:Bitmap = new new Bitmap(textI)
//            // textS.moveTo(1,240+64);
//            audioLayer.addChild(textS);

        stage.addChild(rectB);

        // Download/Upload Box
        // var rectC:Shape = new Shape;
        // rectC.graphics.beginFill(this.opt_mic_fg);
        // rectC.graphics.drawRect(0,240+64,Math.floor(stage.stageWidth),16);
        // rectC.graphics.endFill();
        // stage.addChild(rectC);

    }

    /**
        Load Parameters
    */
    private function readParameters():void
    {
        // this.loaderInfo.parameters
        // this.loaderInfo.parameters

    }

} // Class
} // Package

