/**
* jQuery AS3 Webcam
*
* Copyright (c) 2012, Sergey Shilko (sergey.shilko@gmail.com)
*
* @author Sergey Shilko
* @see https://github.com/sshilko/jQuery-AS3-Webcam
*
**/
try {
$(document).ready(function() {

    var pf = {};

    pf.objId = 'pf-widget';
    pf.swfCallbackTarget = 'pf',
    pf.swfURI = 'preflight.swf';

    pf.camWidth = 320;
    pf.camHeight = 240;

//        previewWidth: 320,
//        previewHeight: 240,
//
//        resolutionWidth: 320,
//        resolutionHeight: 240,
//
//        videoDeblocking: 0,
//        videoSmoothing: 0,
//
//        StageScaleMode: 'exactFit',
//
//        bgcolor: '#000000',
//        isSwfReady: false,
//        isCameraEnabled: false,

    pf.log = function (m) {
        console.log('preflight: ' + m);
    };
                                                                                                                                                        
    pf.camEnabled =   function () { pf.log('camEnabled'); };
    pf.camDisabled =  function () { pf.log('camDisabled'); };
    pf.camNotFound =   function () { pf.log('camNotFound'); };
    
    pf.micEnabled =   function () { pf.log('micEnabled'); };
    pf.micDisabled =  function () { pf.log('micDisabled'); };
    pf.micNotFound =   function () { pf.log('micNotFound'); };

    pf.isClientReady =   function () { return true; };
    pf.cameraReady =     function () { };
    pf.cameraConnected = function () {

        this.isSwfReady = true;
        var cam = document.getElementById(this.objId);

        this.save          = function()  { try { return cam.save();          } catch(e) { this.log(e); } }
        this.setCamera     = function(i) { try { return cam.setCamera(i);    } catch(e) { this.log(e); } }
        this.getCameraList = function()  { try { return cam.getCameraList(); } catch(e) { this.log(e); } }
        this.getResolution = function()  { try { return cam.getResolution(); } catch(e) { this.log(e); } },

        this.cameraReady();
    };

    /**
        Initialise the Preflight
    */
    pf.init = function(container, options)
    {
        if (typeof options === "object") {
            for (var ndx in webcam) {
                if (options[ndx] !== undefined) {
                    webcam[ndx] = options[ndx];
                }
            }
        }

        var obj = '<object id="' + this.objId + '" type="application/x-shockwave-flash" data="' + pf.swfURI + '" width="' + pf.previewWidth+'" height="'+pf.previewHeight+'">';
        obj += '<param name="bgcolor" value="' + pf.bgcolor + '" />';
        obj += '<param name="movie" value="' + pf.swfURI + '" />';
        obj += '<param name="FlashVars" value="callTarget=' + this.swfCallbackTarget+'&resolutionWidth='+pf.resolutionWidth+'&resolutionHeight='+pf.resolutionHeight+'&smoothing='+pf.videoSmoothing+'&deblocking='+pf.videoDeblocking+'&StageScaleMode='+pf.StageScaleMode+'" />';
        obj += '<param name="allowScriptAccess" value="always" />';
        obj += '<param name="menu" value="false" />';
        obj += '</object>';

        $(container).html(obj);

        return this;
    };

    window.preflight = pf;
    $.fn.preflight = function(options) { return pf.init(this, options); };
});
} catch (e) {
    console.log('preflight exception: ' + e);
}
