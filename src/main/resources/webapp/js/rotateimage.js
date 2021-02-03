
var passportUrl;
var photoUrl;
var signatureUrl;

var passportBlob;
var photoBlob;
var signatureBlob;

var originalPassportUrl;
var originalPhotoUrl;
var originalSignatureUrl;

var originalPassportBlob;
var originalPhotoBlob;
var originalSignatureBlob;

var passportRotateDegree;
var photoRotateDegree;
var signatureRotateDegree;

var passportImageSaved = false;
var passportImageModifiedSecs = 0;


function renderImage( file, id ) {

  console.log('renderImage: ', file, ' ', id);

  var reader = new FileReader();
  reader.onload = function(event) {

    var fileUrl = event.target.result;

    const img = new Image(); // large image
    img.src = fileUrl;
    img.onload = () => {


      if( ( img.width == 900 && img.height < img.width ) || ( img.height == 900 && img.width < img.height ) ) { // не сжимаем

        console.log('Loaded with no resize: ', file);
        console.log('Last modified: ', file.lastModified );
        passportImageModifiedSecs = Math.floor( file.lastModified / 1000 );

        onOriginalResizedImageReady( fileUrl, file, id );
        onRenderImageReady( fileUrl, file, id );

        if( id == 'passportfile' ) {

          passportImageSaved = true;

          var savepassportfile = document.querySelector('#savepassportfile');
          if( savepassportfile )
            savepassportfile.style.display = 'none';
        }
      }
      else {

        resizeImage( img, id, function( url, blob, id ) {

          onOriginalResizedImageReady( url, blob, id );

          if( id == 'passportfile' || id == 'signaturefile' ) {

            drawWaterMark( url, blob, id, onRenderImageReady );
          }
          else {

            onRenderImageReady( url, blob, id );
          }
        });
      }
    };
  };

  reader.readAsDataURL(file);
}

function onOriginalResizedImageReady( url, blob, id ) {

  if( id == 'passportfile' ) {

    originalPassportUrl = url;
    originalPassportBlob = blob;
    passportRotateDegree = 0;
  }

  else if( id == 'photofile' ) {

    originalPhotoUrl = url;
    originalPhotoBlob = blob;
    photoRotateDegree = 0;
  }

  else if( id == 'signaturefile' ) {

    originalSignatureUrl = url;
    originalSignatureBlob = blob;
    signatureRotateDegree = 0;
  }
}

function onRenderImageReady( url, blob, id ) {

  if( id == 'passportfile' ) {

    passportUrl = url;
    passportBlob = blob;

    hashPassportImage( blob );
  }

  else if( id == 'photofile' ) {

    photoUrl = url;
    photoBlob = blob;
  }

  else if( id == 'signaturefile' ) {

    signatureUrl = url;
    signatureBlob = blob;
  }

  document.querySelector('#'+id).parentElement.querySelector('.preview').innerHTML = "<img src='" + url + "' />";


  if( id == 'passportfile' ) {

    passportImageSaved = false;

    var savepassportfile = document.querySelector('#savepassportfile');
    if( savepassportfile )
      savepassportfile.style.display = 'inline-block';
  }
}

function normalizeDegrees( degrees ) {

  var negative = degrees < 0;

  degrees = Math.abs( degrees );
  while( degrees >= 360 )
    degrees -= 360;

  if( negative )
    degrees = -degrees;

  return degrees;
}

function resizeImage( img, id, ondone ) {

  var elem = document.createElement('canvas');
  var ctx;

  if( img.width > img.height ) {

    var width = 900;
    var scaleFactor = width / img.width;

    elem.width = width;
    elem.height = img.height * scaleFactor;

    ctx = elem.getContext('2d');

    // img.width and img.height will contain the original dimensions
    ctx.drawImage(img, 0, 0, elem.width, elem.height);
  }
  else if( img.height > img.width ) {

    var height = 900;
    var scaleFactor = height / img.height;

    elem.width = img.width * scaleFactor;
    elem.height = height;

    ctx = elem.getContext('2d');

    // img.width and img.height will contain the original dimensions
    ctx.drawImage(img, 0, 0, elem.width, elem.height);
  }

  ctx.canvas.toBlob( (blob) => {

      // window.imageBlob = blob;

      console.log('resized Blob obtained. size: ', blob.size );

      // const file = new File( [blob], fileName, {
      //     type: 'image/jpeg',
      //     lastModified: Date.now()
      // });

      var url = window.URL.createObjectURL(blob);

      if( ondone )
        ondone( url, blob, id );

  }, 'image/jpeg', 0.8);
}


function drawWaterMark( url, blob, id, ondone ) {

  const img = new Image();
  img.src = url;
  img.onload = () => {

    var elem = document.createElement('canvas');
    var ctx;

    elem.width = img.width;
    elem.height = img.height;

    ctx = elem.getContext('2d');

    ctx.drawImage(img, 0, 0, elem.width, elem.height);

    if( elem.width > img.height ) {

      var text = 'только для голосования';
      ctx.font = "70px Arial";
      ctx.strokeStyle = "#ff0000b4";

      var x = img.width / 2;

      ctx.textAlign = "center";
      ctx.strokeText( text, x, 100);
      ctx.strokeText( text, x, 200);
      ctx.strokeText( text, x, 300);
      ctx.strokeText( text, x, 400);
      ctx.strokeText( text, x, 500);
      ctx.strokeText( text, x, 600);
      ctx.strokeText( text, x, 700);
      ctx.strokeText( text, x, 800);
    }
    else if( img.height > img.width ) {

      var text = 'только для голосования';
      ctx.font = "50px Arial";
      ctx.strokeStyle = "#ff0000b4";

      var x = img.width / 2;

      ctx.textAlign = "center";
      ctx.strokeText( text, x, 100);
      ctx.strokeText( text, x, 200);
      ctx.strokeText( text, x, 300);
      ctx.strokeText( text, x, 400);
      ctx.strokeText( text, x, 500);
      ctx.strokeText( text, x, 600);
      ctx.strokeText( text, x, 700);
      ctx.strokeText( text, x, 800);
    }

    ctx.canvas.toBlob( (blob) => {

        console.log('resized Blob obtained. size: ', blob.size );

        var url = window.URL.createObjectURL(blob);

        if( ondone )
          ondone( url, blob, id );

    }, 'image/jpeg', 0.8);
  };
}

function rotateImage( evt ) {

  var id = evt.target.getAttribute('id');
  var originalUrl;
  var originalBlob;
  var degrees;
  var degreesValue;

  if( id.includes('left') )
    degrees = -90;
  else if( id.includes('right') )
    degrees = 90;

  if( id.includes('passport') ) {
    originalUrl = originalPassportUrl;
    originalBlob = originalPassportBlob;
    passportRotateDegree = normalizeDegrees( passportRotateDegree + degrees );
    degreesValue = passportRotateDegree;
  }

  else if( id.includes('photo') ) {
    originalUrl = originalPhotoUrl;
    originalBlob = originalPhotoBlob;
    photoRotateDegree = normalizeDegrees( photoRotateDegree + degrees );
    degreesValue = photoRotateDegree;
  }

  else if( id.includes('signature') ) {
    originalUrl = originalSignatureUrl;
    originalBlob = originalSignatureBlob;
    signatureRotateDegree = normalizeDegrees( signatureRotateDegree + degrees );
    degreesValue = signatureRotateDegree;
  }

  // console.log('url: ', url);

  if( Math.abs( degreesValue ) == 0 ) { // если поворота нет, то берём оригинальное изображение

    console.log('rotated blob size origianal: ', originalBlob.size, ' width height: ',  );

    onImageRotated( originalUrl, originalBlob, id );
  }
  else {

    const img = new Image(); // small image
    img.src = originalUrl;
    img.onload = () => {

      var elem = document.createElement('canvas');
      var ctx;

      if( Math.abs( degreesValue ) == 90 || Math.abs( degreesValue ) == 270 ) {

        elem.width = img.height;
        elem.height = img.width;

        ctx = elem.getContext('2d');

        ctx.translate( elem.width/2, elem.height/2 );
        ctx.rotate( degreesValue * Math.PI / 180 );
        ctx.drawImage(img, -elem.height/2, -elem.width/2);
      }
      else if( Math.abs( degreesValue ) == 180 ) {

        elem.width = img.width;
        elem.height = img.height;

        ctx = elem.getContext('2d');

        ctx.translate( elem.width/2, elem.height/2 );
        ctx.rotate( degreesValue * Math.PI / 180 );
        ctx.drawImage(img, -elem.width/2, -elem.height/2);
      }

        // ctx.clearRect(0, 0, elem.width, elem.height);

        // ctx.save();

        // ctx.restore();

      ctx.canvas.toBlob( (blob) => {

          // window.imageBlob = blob;

          console.log('rotated Blob obtained. size: ', blob.size, ' width height: ',  );

          var url = window.URL.createObjectURL(blob);

          if( id.includes('passport') ) {

            passportImageSaved = false;
            document.querySelector('#savepassportfile').style.display = 'inline-block';
          }

          onImageRotated( url, blob, id );

      }, 'image/jpeg', 0.8);
    };
  }
}

function onImageRotated( url, blob, id ) {

  if( id.includes('passport') || id.includes('signature') ) {

    drawWaterMark( url, blob, id, onImageRotatedReady );
  }
  else {

    onImageRotatedReady( url, blob, id );
  }
}

function onImageRotatedReady( url, blob, id ) {

  if( id.includes('passport') ) {
    passportUrl = url;
    passportBlob = blob;

    hashPassportImage( blob );
  }

  else if( id.includes('photo') ) {
    photoUrl = url;
    photoBlob = blob;
  }

  else if( id.includes('signature') ) {
    signatureUrl = url;
    signatureBlob = blob;
  }

  document.querySelector('#'+id).parentElement.querySelector('.preview').innerHTML = "<img src='" + url + "' />";

  if( id.includes('passport') ) {

    hashPassportImage( blob );
  }
}

function hashPassportImage( blob ) {

	var reader = new FileReader();
  reader.onload = function() {

    var arrayBuffer = this.result;
    var bytes = new Uint8Array( arrayBuffer );
    document.querySelector("#passportimagehash").value = sha256( bytes );

  }
  reader.readAsArrayBuffer( blob );
}

function savePassportFile() {

  var a = document.createElement("a");
  document.body.appendChild(a);
  a.style = "display: none";

  var url = window.URL.createObjectURL( passportBlob );
  a.href = url;
  a.download = 'Паспорт для входа в голосование.jpg';
  //a.title = fileusername;
  //a.innerHTML = fileusername;

  a.click();
  window.URL.revokeObjectURL(url);

  document.body.removeChild( a );

  passportImageSaved = true;
  passportImageModifiedSecs = Math.floor( new Date().getTime() / 1000 );

  document.querySelector('#savepassportfile').style.display = 'none';
}

