<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>


<html>
<head>
  <title>Подсчёт голосов</title>
  <style>

.preview img {

  max-width: 400px;
  max-height: 400px;
}

table#votestable {
  border: 1px solid #C4C1C1;
  /* border-collapse: collapse; */
}

td, th {
  border: 1px solid #C4C1C1;
  text-align: center;
  padding-left: 5px;
  padding-right: 5px;
}

img.passportimg {
  height: 40px;
}

img.signatureimg {
  height: 40px;
}

  </style>
</head>
<body>

<%

Connection dbConn;
Campaign campaign = null;


try {

  dbConn = DbTools.connect();
  campaign = DbTools.getActiveCampaign( dbConn );

  dbConn.close();
}
catch(Exception e) {

  e.printStackTrace();
}

%>

<%
  if( campaign == null ) {
%>
Сейчас не проводится голосование.
</body>
</html>
<%
  } else if( campaign != null ) {
%>
<%= campaign.name %><br>
<%= campaign.description %><br>
<br>



<button id="request">Запросить голоса</button><br>
<br>
<table id="count">
</table>
<br>
Всего голосов: <span id="totalvotes"></span><br>
<br>

<div id="votes">

<table id="votestable">
  <tr>
    <th>№</th>
    <th>ID</th>
    <th>Голос</th>
    <th>Подпись</th>
    <th>Отправлен</th>
    <th>Проверил</th>
    <th>Также проверили</th>
    <th>Сообщить</th>
  </tr>
</table>

</div>

<script>

var votesDataTable = [];

function buildVotesDataTable() {

<% for( int i=0; i<campaign.data.length; i++ ) {

  String display = campaign.data[i][0];
  String code = campaign.data[i][1];
%>
  votesDataTable.push( [ '<%= code %>' , '<%= display %>', 0 /*count*/, 0 /* percent */ ] );
<% } %>
}

function buildCountDiv() {

  for( var i=0; i<votesDataTable.length; i++ ) {

    var voteelementtr = document.createElement('tr');
    voteelementtr.setAttribute('data-code', votesDataTable[i][0]);

    var displaytd = document.createElement('td');
    displaytd.className = 'voteDisplay';
    displaytd.innerText = votesDataTable[i][1];

    var counttd = document.createElement('td');
    counttd.className = 'countValue';
    counttd.innerText = '0';

    var countpercenttd = document.createElement('td');
    countpercenttd.className = 'countPercent';
    countpercenttd.innerText = '0%';

    voteelementtr.appendChild( displaytd );
    voteelementtr.appendChild( counttd );
    voteelementtr.appendChild( countpercenttd );

    document.querySelector('#count').appendChild( voteelementtr );
  }
}

function getVoteDisplayByCode( code ) {

  for( var i=0; i<votesDataTable.length; i++ )
    if( votesDataTable[i][0] == code )
      return votesDataTable[i][1];

  return null;
}

function plusVote( code ) {

  for( var i=0; i<votesDataTable.length; i++ )
    if( votesDataTable[i][0] == code ) {

      votesDataTable[i][2] += 1;

      votesDataTable[i][3] = votesDataTable[i][2] / votes.length * 100;
    }

  document.querySelector('#totalvotes').innerText = votes.length;
}

function updateCountDiv() {

  for( var i=0; i<votesDataTable.length; i++ ) {

    document.querySelector('#count tr[data-code="'+votesDataTable[i][0]+'"] td.countValue').innerText = votesDataTable[i][2];
    document.querySelector('#count tr[data-code="'+votesDataTable[i][0]+'"] td.countPercent').innerText = votesDataTable[i][3]+'%';
  }
}

buildVotesDataTable();
buildCountDiv();

document.querySelector('#request').addEventListener('click', loadAllVotes, false);

var numberfrom = 0;
var votes = [];
var nloadedvotes;
var loadresult = { n: 0, lastnumber: 0 };

function loadAllVotes() {

  if( votes.length > 0 ) {
    alert('Голоса уже запрошены и подсчитаны.');
    return;
  }

  numberfrom = 0;
  votes = [];

  document.querySelector('#request').disabled = true;

  loadVotesIter();
}

function loadVotesIter() {

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          loadresult = parseVotes( this.responseText );

          if( loadresult.n > 0 ) {

            var istart = votes.length - loadresult.n;
            for( var i=istart; i<votes.length; i++ ) {

              plusVote( votes[i][2] /* code */ );

              updateCountDiv();

              addVoteToDisplay( votes[i] );
            }

            numberfrom += loadresult.lastnumber;

            sleep( 500 );

            loadVotesIter();
          }
          else if( loadresult.n == 0 ) {

            if( votes.length == 0 ) {

              document.querySelector('#totalvotes').innerText = votes.length;
              updateCountDiv();
            }

            document.querySelector('#request').disabled = false;

            alert('Голоса загружены.');
          }

        } else {

           console.log('Обрыв соединения. Загрузка продолжится автоматически.');

           sleep( 500 );

           loadVotesIter();
        }
      }
  };



  xmlhttp.open('GET', '/count/load?campaignid=<%= campaign.id %>&numberfrom='+numberfrom, true);
  xmlhttp.send();
}

function sleep( ms ) {
  ms += new Date().getTime();
  while( new Date().getTime() < ms ) {}
}

function parseVotes( data ) {

/*
n 1

4
AC3569274
thnk
1610609770681
AC3569274
{}
*/

  if( data.charAt(0) != 'n' && data.charAt(1) != ' ' ) {
    alert('Неверный ответ от сервера.');
    return;
  }

  var firstLine = getLine( data, 0 );

  var n = Number( firstLine.split(' ')[1] );

  var i = 0 + firstLine.length + '\n\n'.length;
  var number;
  var id;
  var votedata;
  var senttime;
  var sentdisplay;
  var checkerid;
  var sothercheckers;
  var othercheckers;

  var line;

  for( var ni=0; ni<n; ni++ ) {

    line = getLine( data, i );
    number = Number( line );
    i += line.length + 1;

    line = getLine( data, i );
    id = line;
    i += line.length + 1;

    line = getLine( data, i );
    votedata = line;
    i += line.length + 1;

    line = getLine( data, i );
    senttime = Number( line );
    i += line.length + 1;

    line = getLine( data, i );
    checkerid = line;
    i += line.length + 1;

    line = getLine( data, i );
    sothercheckers = line;
    i += line.length + 1;

    i++; // \n

    sentdisplay = new Date( senttime ).toISOString();
    othercheckers = parseOthercheckers( sothercheckers );

    votes.push( [ number, id, votedata, senttime, sentdisplay, checkerid, othercheckers ] );
  }

  console.log( votes );

  loadresult.n = n;
  loadresult.lastnumber = number;

  return loadresult;
}

function getLine( data, ifrom ) {

  for( var i=ifrom; i<data.length; i++ ) {

    if( data.charAt(i) == '\n' ) {

      return data.substring(ifrom, i);
    }
  }

  return null;
}


function parseOthercheckers( sothercheckers ) {

  var othercheckers;

  sothercheckers = sothercheckers.substring(1, sothercheckers.length-1);

  if( sothercheckers.length == 0 )
    othercheckers = [];
  else
    othercheckers = sothercheckers.split(",");

  return othercheckers;
}

function addVoteToDisplay( vote ) {

  var votetr = document.createElement('tr');

  var numbertd = document.createElement('td');
  var idtd = document.createElement('td');
  var votedatatd = document.createElement('td');
  var signaturetd = document.createElement('td');
  var displaytimetd = document.createElement('td');
  var checkeridtd = document.createElement('td');
  var othercheckerstd = document.createElement('td');
  var falsificationtd = document.createElement('td');

  numbertd.innerText = vote[0];
  idtd.innerHTML = '<a href="/files/id/'+vote[1]+'.jpg"><img class="passportimg" src="/files/id/'+vote[1]+'.jpg"></a>';
  votedatatd.innerText = getVoteDisplayByCode( vote[2] );
  signaturetd.innerHTML = '<a href="/files/sig/'+'<%= campaign.id %>'+'_'+vote[1]+'.jpg"><img class="signatureimg" src="/files/sig/'+'<%= campaign.id %>'+'_'+vote[1]+'.jpg">';
  checkeridtd.innerHTML = '<a href="/files/checkers/id/'+vote[5]+'.jpg">'+vote[5]+'</a>';
  displaytimetd.innerText = vote[4];
  checkeridtd.innerHTML = '<a href="/files/checkers/id/'+vote[5]+'.jpg"><img class="passportimg" src="/files/checkers/id/'+vote[5]+'.jpg"></a>';

  // othercheckers
  for( var i=0; i<vote[6].length; i++ ) {

    othercheckerstd.innerHTML += '<a href="/files/id/'+vote[6][i]+'.jpg"><img class="passportimg" src="/files/id/'+vote[6][i]+'.jpg"></a>';
  }

  falsificationtd.innerHTML = '<button onclick="error(\''+vote[1]+'\')">-></button>';

  votetr.appendChild( numbertd );
  votetr.appendChild( idtd );
  votetr.appendChild( votedatatd );
  votetr.appendChild( signaturetd );
  votetr.appendChild( displaytimetd );
  votetr.appendChild( checkeridtd );
  votetr.appendChild( othercheckerstd );
  votetr.appendChild( falsificationtd );

  document.querySelector('#votestable').appendChild( votetr );
}

function error( voterid ) {

  var message = prompt("В чём несоответствие, кратко:", "");
  if( message == null )
    return;

  var formData = new FormData();
  formData.append('voterid', voterid );
  formData.append('campaignid', '<%= campaign.id %>' );
  formData.append('who', 'helper' );
  formData.append('state', 'error' );
  formData.append('message', message );
  formData.append('checkerid', '<%= request.getSession().getAttribute("voterid").toString() %>' );

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
      if (this.readyState == 4) {

        if( this.status == 200 ) {

          alert('Отправлено.');

        } else {

          alert('Не отправлено');
        }
      }
  };

  xmlhttp.open('POST', '/check', true);
  xmlhttp.send( formData );
}


</script>

<% } %>

<br>
<br>
<a href="/">На главную</a><br>
<br>
<br>

</body>
</html>