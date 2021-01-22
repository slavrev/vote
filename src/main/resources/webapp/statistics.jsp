<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="org.vote.tools.DbTools" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.vote.model.Campaign" %>
<%@ page import="org.vote.model.Locality" %>
<%@ page import="org.vote.model.District" %>
<%@ page import="java.util.List" %>

<html>
<head>
  <title>Статистика голосования</title>
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

List<Locality> localities = null;

try {

  dbConn = DbTools.connect();
  campaign = DbTools.getActiveCampaign( dbConn );

  localities = DbTools.loadLocalities( dbConn );

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

  Населённый пункт:
  <select id="localityid">
  <% for( Locality locality : localities ) {
  %>
    <option value="<%= locality.id %>"><%= locality.name %></option>
  <% } %>
  </select>

  Район:
  <select id="districtid">
    <option value="xxxx">Другое</option>
  </select><br>
  <br>

Запросить статистку:<br>
<br>
<button id="total">Полную</button> <button id="locality">По нас.пункту</button> <button id="district">По району</button><br>
<br>

<div id="statistics">
<div id="statisticsby">Статистика по</div>
<br>
Всего голосов: <span id="votesnumber"></span><br>
<br>
<table id="table">
</table>
</div>

<table id="count">
</table>
<br>

<script>


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
    countpercenttd.innerText = '0';

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

document.querySelector('#statistics').style.display = 'none';

document.querySelector('#localityid').addEventListener('change', loadDistricts, false);
document.querySelector('#localityid').value = 'xxxx';

document.querySelector('#total').addEventListener('click', loadStatisticsTotal, false);
document.querySelector('#locality').addEventListener('click', loadStatisticsLocality, false);
document.querySelector('#district').addEventListener('click', loadStatisticsDistrict, false);



function loadDistricts() {

  var localityid = document.querySelector('#localityid').value;

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {

      if (this.readyState == 4) {

        if( this.status == 200 ) {

          var json = JSON.parse( this.responseText );

          var districtElement = document.querySelector('#districtid');

          while( districtElement.firstChild )
            districtElement.removeChild( districtElement.lastChild );

          for( var i=0; i<json.length; i++ ) {

            var option = document.createElement('option');
            option.value = json[i].id;
            option.innerText = json[i].name;

            districtElement.appendChild( option );
          }

          districtElement.value = 'xxxx';

        } else {


        }
      }
  };

  xmlhttp.open("GET", "/getdistricts?localityid="+localityid, true);
  xmlhttp.send();
}

function loadStatisticsTotal() {

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {

      if (this.readyState == 4) {

        if( this.status == 200 ) {

          document.querySelector('#statisticsby').innerText = 'Статистика полная';

          updateGui( this.responseText );

        } else {

          alert('Ошибка загрузки');
        }
      }
  };

  xmlhttp.open('GET', '/statistics/total?campaignid=<%= campaign.id %>', true);
  xmlhttp.send();
}

function updateGui( responseText ) {

  var json = JSON.parse( responseText );

  document.querySelector('#votesnumber').innerText = json.votesnumber;

  var table = document.querySelector('#table');
  while( table.firstChild )
     table.removeChild( table.firstChild );

  for( var i=0; i<json.elements.length; i++ )
    addElementToTable( json.elements[i] );

  document.querySelector('#statistics').style.display = 'block';
}

function loadStatisticsLocality() {

  var localityid = document.querySelector('#localityid').value;

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {

      if (this.readyState == 4) {

        if( this.status == 200 ) {

          var locality = document.querySelector('#localityid option[value='+localityid+']').innerText;

          document.querySelector('#statisticsby').innerHTML = 'Статистика по<br>Нас.пункту: '+locality;

          updateGui( this.responseText );

        } else {

          alert('Ошибка загрузки');
        }
      }
  };

  xmlhttp.open('GET', '/statistics/locality?campaignid=<%= campaign.id %>&localityid='+localityid, true);
  xmlhttp.send();
}

function loadStatisticsDistrict() {

  var localityid = document.querySelector('#localityid').value;
  var districtid = document.querySelector('#districtid').value;

  var xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {

      if (this.readyState == 4) {

        if( this.status == 200 ) {

          var locality = document.querySelector('#localityid option[value='+localityid+']').innerText;
          var district = document.querySelector('#districtid option[value='+districtid+']').innerText;

          document.querySelector('#statisticsby').innerHTML = 'Статистика по<br>Нас.пункту: '+locality+'<br>Район: '+district;

          updateGui( this.responseText );

        } else {

          alert('Ошибка загрузки');
        }
      }
  };

  xmlhttp.open('GET', '/statistics/district?campaignid=<%= campaign.id %>&localityid='+localityid+'&districtid='+districtid, true);
  xmlhttp.send();
}

function addElementToTable( element ) {

  var elementtr = document.createElement('tr');

  var displaytd = document.createElement('td');
  var votesnumbertd = document.createElement('td');
  var percenttd = document.createElement('td');

  displaytd.innerText = element.display;
  votesnumbertd.innerText = element.votesnumber;

  var totalvotesnumber = Number( document.querySelector('#votesnumber').innerText );
  if( totalvotesnumber > 0 )
    percenttd.innerText = element.votesnumber / Number( document.querySelector('#votesnumber').innerText ) * 100 + '%';
  else
    percenttd.innerText = '0%'

  elementtr.appendChild( displaytd );
  elementtr.appendChild( votesnumbertd );
  elementtr.appendChild( percenttd );

  document.querySelector('#table').appendChild( elementtr );
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