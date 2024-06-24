<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="/WEB-INF/views/common/header.jsp"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>여행지도</title>
    <script type="text/javascript" src="https://openapi.map.naver.com/openapi/v3/maps.js?ncpClientId=7whhnl24e7"></script>
    <style>
        body {
            display: block;
            margin: 0;
        }
        #mapContainer {
            display: flex;
            width: 100%;
            height: calc(100vh - 60px);
        }
        #map {
            width: 100%;
            height: 100%;
            transition: width 0.3s;
        }
        #sidebar {
            width: 30%;
            height: 100%;
            overflow-y: auto;
            background-color: #ffffff;
            padding: 20px;
            box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);
            display: none;
            font-family: Arial, sans-serif;
            color: #333;
        }
        #sidebar h2 {
            font-size: 24px;
            margin-bottom: 20px;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        #sidebar p {
            margin: 10px 0;
            line-height: 1.6;
        }
        #sidebar img {
            margin-top: 20px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        #searchAgainBtn {
            display: none;
            position: absolute;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 10;
            padding: 10px 20px;
            background-color: #007bff;
            color: #fff;
            border: none;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            cursor: pointer;
            font-size: 16px;
        }
        #searchAgainBtn:hover {
            background-color: #0056b3;
        }
        #searchForm {
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 20px 0;
        }
        #searchInput {
            width: 300px;
            padding: 10px;
            font-size: 16px;
            border: 1px solid #ddd;
            border-radius: 5px;
        }
        #searchBtn {
            padding: 10px 20px;
            margin-left: 10px;
            background-color: #007bff;
            color: #fff;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        #searchBtn:hover {
            background-color: #0056b3;
        }
        #suggestions {
            border: 1px solid #ddd;
            border-top: none;
            max-height: 200px;
            overflow-y: auto;
            position: absolute;
            width: 300px;
            background: #fff;
            z-index: 1000;
            display: none;
        }
        #suggestions div {
            padding: 10px;
            cursor: pointer;
        }
        #suggestions div:hover {
            background-color: #f1f1f1;
        }
    </style>
</head>
<body>
    <div id="searchForm">
        <input type="text" id="searchInput" placeholder="검색어를 입력하세요">
        <button id="searchBtn">검색</button>
        <div id="suggestions"></div>
    </div>
    <div id="mapContainer">
        <div id="map"></div>
        <div id="sidebar">
            <h2 id="title"></h2>
            <p id="addr1Wrapper"><strong>주소:</strong> <span id="addr1"></span></p>
            <p id="addr2Wrapper"><strong>상세 주소:</strong> <span id="addr2"></span></p>
            <p id="firstimageWrapper"><strong>대표 이미지:</strong></p>
            <img id="firstimage" src="" alt="대표 이미지" style="width:100%; height:auto;">
        </div>
    </div>
    <button id="searchAgainBtn" onclick="searchAgain()">현위치에서 주변 관광지 검색하기</button>

    <script>
        var mapX = ${mapX};
        var mapY = ${mapY};
        var keyword = '${keyword}';

        var mapOptions = {
            center: new naver.maps.LatLng(mapY, mapX),
            zoom: 14  // 줌 레벨
        };

        var map = new naver.maps.Map('map', mapOptions);

        // 관광 데이터 파싱 및 마커 추가
        var touristData = '${touristData}';
        var markers = [];

        if (touristData) {
            try {
                var parsedData = JSON.parse(touristData);
                var items = parsedData.response.body.items.item;

                if (items && items.length) {
                	//검색어와 일치하는 관광지를 찾음
                    var matchedItem = items.find(function(location) {
                        return location.title === keyword;
                    });

                    if (matchedItem) {
                        // 기존 마커들을 모두 제거
                        markers.forEach(function(marker) {
                            marker.setMap(null);
                        });
                        markers = [];

                        // 일치하는 관광지의 마커 추가
                        var marker = new naver.maps.Marker({
                            position: new naver.maps.LatLng(parseFloat(matchedItem.mapy), parseFloat(matchedItem.mapx)),
                            map: map,
                            title: matchedItem.title,
                            icon: {
                                url: 'https://navermaps.github.io/maps.js/docs/img/example/pin_default.png',
                                size: new naver.maps.Size(70, 70),
                                scaledSize: new naver.maps.Size(70, 70),
                                origin: new naver.maps.Point(0, 0),
                                anchor: new naver.maps.Point(35, 70)
                            }
                        });

                        var infowindow = new naver.maps.InfoWindow({
                            content: '<div style="width:150px;text-align:center;padding:10px;">' + matchedItem.title + '</div>'
                        });

                        naver.maps.Event.addListener(marker, "mouseover", function(e) {
                            infowindow.open(map, marker);
                        });

                        naver.maps.Event.addListener(marker, "mouseout", function(e) {
                            infowindow.close();
                        });

                        naver.maps.Event.addListener(marker, "click", function(e) {
                            displaySidebar(matchedItem);
                        });

                        markers.push(marker);

                        map.setCenter(new naver.maps.LatLng(parseFloat(matchedItem.mapy), parseFloat(matchedItem.mapx)));
                        displaySidebar(matchedItem);
                    } else {
                        //일치하는 관광지가 없을 경우, 모든 관광지 마커 추가
                        var bounds = new naver.maps.LatLngBounds();
                        items.forEach(function(location) {
                            var marker = new naver.maps.Marker({
                                position: new naver.maps.LatLng(parseFloat(location.mapy), parseFloat(location.mapx)),
                                map: map,
                                title: location.title,
                                icon: {
                                    url: 'https://navermaps.github.io/maps.js/docs/img/example/pin_default.png',
                                    size: new naver.maps.Size(70, 70), // 마커 크기를 70x70으로 변경
                                    scaledSize: new naver.maps.Size(70, 70),
                                    origin: new naver.maps.Point(0, 0),
                                    anchor: new naver.maps.Point(35, 70) // 앵커 포인트 조정
                                }
                            });

                            var infowindow = new naver.maps.InfoWindow({
                                content: '<div style="width:150px;text-align:center;padding:10px;">' + location.title + '</div>'
                            });

                            naver.maps.Event.addListener(marker, "mouseover", function(e) {
                                infowindow.open(map, marker);
                            });

                            naver.maps.Event.addListener(marker, "mouseout", function(e) {
                                infowindow.close();
                            });

                            naver.maps.Event.addListener(marker, "click", function(e) {
                                displaySidebar(location);
                            });

                            markers.push(marker);
                            bounds.extend(new naver.maps.LatLng(parseFloat(location.mapy), parseFloat(location.mapx)));
                        });
                        //모든 마커를 포함하도록 지도 중심 조정 및 줌 레벨 조정
                        map.panToBounds(bounds);
                        map.setZoom(map.getZoom() - 1);  // 여기에서 줌 레벨을 한 단계 축소
                    }
                } else {
                    document.write("No items found in the response");
                }
            } catch (e) {
                document.write("Error parsing JSON data: " + e);
            }
        } else {
            document.write("No touristData available");
        }

        // 지도 클릭 이벤트 처리 : 사이드 바 숨기기
        naver.maps.Event.addListener(map, 'click', function(e) {
            hideSidebar();
        });

        // 지도 이동 이벤트 처리 : 다시 검색 버튼 표시
        naver.maps.Event.addListener(map, 'dragend', function() {
            document.getElementById('searchAgainBtn').style.display = 'block';
        });

        // 현재 지도 중심에서 다시 검색
        function searchAgain() {
            var center = map.getCenter();
            var mapX = center.lng();
            var mapY = center.lat();

            window.location.href = '${pageContext.request.contextPath}/travelMap?mapX=' + encodeURIComponent(mapX) + '&mapY=' + encodeURIComponent(mapY);
        }

        //사이드바에 관광지 정보 표시
        function displaySidebar(location) {
            var sidebar = document.getElementById('sidebar');
            var mapDiv = document.getElementById('map');

            document.getElementById('title').innerText = location.title || '정보 없음';

            if (location.addr1) {
                document.getElementById('addr1Wrapper').style.display = 'block';
                document.getElementById('addr1').innerText = location.addr1;
            } else {
                document.getElementById('addr1Wrapper').style.display = 'none';
            }

            if (location.addr2) {
                document.getElementById('addr2Wrapper').style.display = 'block';
                document.getElementById('addr2').innerText = location.addr2;
            } else {
                document.getElementById('addr2Wrapper').style.display = 'none';
            }

            var firstImageElement = document.getElementById('firstimageWrapper');
            if (location.firstimage) {
                firstImageElement.style.display = 'block';
                document.getElementById('firstimage').src = location.firstimage;
            } else {
                firstImageElement.style.display = 'none';
            }

            sidebar.style.display = 'block';
            mapDiv.style.width = '70%';
        }

        //사이드 바 숨기기
        function hideSidebar() {
            var sidebar = document.getElementById('sidebar');
            var mapDiv = document.getElementById('map');

            sidebar.style.display = 'none';
            mapDiv.style.width = '100%';
        }

        // 검색 버튼 클릭 이벤트
        document.getElementById('searchBtn').addEventListener('click', function() {
            var keyword = document.getElementById('searchInput').value;
            if (keyword) {
                window.location.href = '${pageContext.request.contextPath}/travelMap?keyword=' + encodeURIComponent(keyword);
            }
        });

        // 검색 입력 이벤트 처리: 실시간 검색어 제안
        document.getElementById('searchInput').addEventListener('input', function() {
            var term = document.getElementById('searchInput').value;
            if (term.length >= 2) {
                fetchRelatedTerms(term);
            } else {
                document.getElementById('suggestions').style.display = 'none';
            }
        });

        // 서버에서 관련 검색어 가져오기
        function fetchRelatedTerms(term) {
            fetch('${pageContext.request.contextPath}/relatedSearchTerms?term=' + encodeURIComponent(term))
                .then(response => response.json())
                .then(data => {
                    displaySuggestions(data);
                });
        }

        // 검색어 제안 표시
        function displaySuggestions(suggestions) {
            var suggestionsContainer = document.getElementById('suggestions');
            suggestionsContainer.innerHTML = '';

            if (suggestions.length > 0) {
                suggestions.forEach(term => {
                    var suggestionDiv = document.createElement('div');
                    suggestionDiv.textContent = term;
                    suggestionDiv.addEventListener('click', function() {
                        document.getElementById('searchInput').value = term;
                        suggestionsContainer.style.display = 'none';
                    });
                    suggestionsContainer.appendChild(suggestionDiv);
                });
                suggestionsContainer.style.display = 'block';
            } else {
                suggestionsContainer.style.display = 'none';
            }
        }
    </script>
</body>
</html>
