<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>

<html>
<head>
  <title>Войти</title>
  <script type="text/javascript" src="/js/sha256.js"></script>
  <script type="text/javascript" src="/js/rotateimage.js"></script>
  <style>

.preview img {

  max-width: 600px;
  max-height: 600px;
}

  </style>
</head>
<body>


  Введите номер паспорта<br>
  <input type="text" id="id" name="id" value=""><br>
  <br>

  <div>
    Ваш паспорт <input id="passportfile" type="file" style="display:none">
    <button onclick="document.querySelector('#passportfile').click()">Обзор...</button>
    <!-- <button id="rotatepassportleft">Повернуть</button> -->
    <button id="rotatepassportright">Повернуть</button>
    <button id="savepassportfile" style="display:none">Сохранить</button>
    <div class="preview">
    </div>
    <input type="hidden" id="passportimagehash" name="passportimagehash" value="">
  <div>
  <br>

  <button id="enterbutton">Войти</button>

<script>

document.querySelector('#passportfile').addEventListener('change', handleFileSelect, false);

<!-- document.querySelector('#rotatepassportleft').addEventListener('click', rotateImage, false); -->
document.querySelector('#rotatepassportright').addEventListener('click', rotateImage, false);
document.querySelector('#savepassportfile').addEventListener('click', savePassportFile, false);

document.querySelector('#enterbutton').addEventListener('click', enter, false);

function handleFileSelect(evt) {
  var files = evt.target.files;
  var file = files[0];

  var id = evt.target.getAttribute('id');

  renderImage( file, id );

  passporthashchanged = true;
}

function onRotatePassportPressed( evt ) {

  passporthashchanged = true;

  rotateImage( evt );
}

var waswronghash = false;
var passporthashchanged = false;

function enter() {

  var id = document.querySelector('#id').value;
  var passportimagehash = document.querySelector('#passportimagehash').value;

  if( id.length == 0 ) {

    alert('Введите номер паспорта');
    document.querySelector('#id').focus();
    return;
  }

  if( passportBlob == null ) {

    alert('Приложите фото вашего паспорта на развороте');
    return;
  }

  if( !passportImageSaved ) {

    alert('Сохраните изменённое фото паспорта. Иначе вы не сможете войти далее.');
    return;
  }

  if( passportimagehash == null ) {

    alert('Что-то пошло не так. И хэш паспорта не посчитался. Обратитесь в администрацию системы.');
    return;
  }

  var formData = new FormData();
  formData.append('id', id );
  formData.append('passportfile', passportBlob );
  formData.append('passportimagehash', passportimagehash );
  formData.append('registeredsecs', passportImageModifiedSecs );

  var path;

  if( !waswronghash )
    path = '/enter';

  else if( waswronghash ) {

    if( !passporthashchanged )
      path = '/enter';
    else
      path = '/enter/addvoteconflict';
  }

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          var json = JSON.parse( this.responseText );

          if( path == '/enter' ) {

          }

          if( json.failed == 'wronghash') {

            // waswronghash = true;

            var result = confirm('Пользователь с таким id уже зарегистрирован.\nВы точно указали верный паспорт?\nЗарегистрировать такого пользователя всё равно?')

            if( result ) {
              addVoteConflict( formData );
            }
          }

          else if( json.redirect == 'setvoterdata' )
            window.location.href = window.location.protocol+'//'+window.location.hostname+':'+window.location.port+'/setvoterdata?targeturl=<%= request.getParameter("targeturl") %>';

          else if( json.redirect == 'targeturl' )
            window.location.href = window.location.protocol+'//'+window.location.hostname+':'+window.location.port+'<%= request.getParameter("targeturl") %>';

        } else {

          alert('Не отправлено. Попробуйте ещё раз.');
        }
      }
  };

  xmlhttp.open("POST", '/enter', true);
  xmlhttp.send( formData );
}

function addVoteConflict( formData ) {

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          var json = JSON.parse( this.responseText );

          if( json.redirect == 'setvoterdata' ) {

            var conflictid = json.voteconflictid;
            var id = formData.get('id');
            var passportimagehash = formData.get('passportimagehash');

            window.location.href = window.location.protocol+'//'+window.location.hostname+':'+window.location.port+'/setvoterdata/addvoteconflict?targeturl=<%= request.getParameter("targeturl") %>';
          }

        } else {

          alert('Не отправлено. Попробуйте ещё раз.');
        }
      }
  };

  xmlhttp.open("POST", '/enter/addvoteconflict', true);
  xmlhttp.send( formData );
}

</script>

</body>
</html>