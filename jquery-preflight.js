/**
* jQuery Flash Preflight Helper

* @author Edoceo

http://stackoverflow.com/questions/8037252/swf-object-params-scale-or-scalemode
http://learnswfobject.com/advanced-topics/100-width-and-height-in-browser/

*/

try {
$(document).ready(function() {

    var pf = {};

    pf.objId = 'preflight';

    pf.swfURI = 'preflight.swf';
    // pf.swfCallbackTarget = 'pf'; // Hardcodded
    pf.swfWidth = 320;
    pf.swfHeight = 320;

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
        console.log('jquery-preflight.js: ' + m);
    };

    // Interfaces Called By The Object
    pf.onCamFound    = function () { pf.log('onCamFound'); };
    pf.onCamNotFound = function () { pf.log('onCamNotFound'); };
    // pf.camDisabled =  function () { pf.log('camDisabled'); };

    pf.onMicFound    = function () { pf.log('onMicFound'); };
    pf.onMicNotFound = function () { pf.log('onMicNotFound'); };
    pf.onMicCheck = function(l) { pf.log('onMicCheck'); };
    // pf.onMicDisabled =  function () { pf.log('micDisabled'); };

    // pf.isClientReady =   function () { return true; };
    pf.onInit = function () {
         this.log('onInit');
         // this.isSwfReady = true;
         var swf = document.getElementById(this.objId);

         // Attach to SWF Interfaces
         this.save          = function()  { try { return swf.save();          } catch(e) { this.log(e); } }
         this.setCamera     = function(i) { try { return swf.setCamera(i);    } catch(e) { this.log(e); } }
         this.getCameraList = function()  { try { return swf.getCameraList(); } catch(e) { this.log(e); } }
         this.getResolution = function()  { try { return swf.getResolution(); } catch(e) { this.log(e); } }

         // this.cameraReady();
    };

    /**
        Initialise the Preflight
    */
    pf.init = function(container, options)
    {
        if (typeof options === "object") {
            for (var ndx in pf) {
                if ('undefined' != typeof options[ndx]) {
                    pf[ndx] = options[ndx];
                }
            }
        }

        var obj = '<object data="' + pf.swfURI + '" id="' + this.objId + '" type="application/x-shockwave-flash" height="' + pf.swfHeight + '" width="' + pf.swfWidth + '">';
        obj += '<param name="movie" value="' + pf.swfURI + '" />';
        obj += '<param name="scale" value="exactfit" />';
        obj += '<param name="bgcolor" value="' + pf.bgcolor + '" />';
        // obj += '<param name="FlashVars" value="callTarget=' + this.swfCallbackTarget+'&resolutionWidth='+pf.resolutionWidth+'&resolutionHeight='+pf.resolutionHeight+'&smoothing='+pf.videoSmoothing+'&deblocking='+pf.videoDeblocking+'&StageScaleMode='+pf.StageScaleMode+'" />';
        obj += '<param name="FlashVars" value="resolutionWidth='+pf.resolutionWidth+'&resolutionHeight='+pf.resolutionHeight+'&smoothing='+pf.videoSmoothing+'&deblocking='+pf.videoDeblocking+'&StageScaleMode='+pf.StageScaleMode+'" />';
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
