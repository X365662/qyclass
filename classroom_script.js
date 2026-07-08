var xqh = '007';

			var xqList = '[{"campusName":"路南校区","campusNumber":"011","remark":""},{"campusName":"线上教学","campusNumber":"010","remark":""},{"campusName":"主校区","campusNumber":"001","remark":""},{"campusName":"建设路校区","campusNumber":"005","remark":""},{"campusName":"东校区","campusNumber":"002","remark":""},{"campusName":"大学道校区","campusNumber":"004","remark":""},{"campusName":"迁安校区","campusNumber":"003","remark":""},{"campusName":"冀唐校区","campusNumber":"006","remark":""},{"campusName":"轻院丰润校区","campusNumber":"007","remark":""},{"campusName":"曹妃甸校区","campusNumber":"009","remark":""},{"campusName":"路南一校区","campusNumber":"012","remark":""},{"campusName":"路南二校区","campusNumber":"013","remark":""},{"campusName":"路南三校区","campusNumber":"014","remark":""},{"campusName":"滨海校区","campusNumber":"015","remark":""}]';

			var buildings = '[{"013":[{"id":{"campusNumber":"013","teachingBuildingNumber":"第一教学楼"},"remark":"","teachingBuildingName":"第一教学楼"},{"id":{"campusNumber":"013","teachingBuildingNumber":"体育教学"},"remark":"","teachingBuildingName":"体育教学"},{"id":{"campusNumber":"013","teachingBuildingNumber":"实践"},"remark":"","teachingBuildingName":"实践"},{"id":{"campusNumber":"013","teachingBuildingNumber":"第二教学楼"},"remark":"","teachingBuildingName":"第二教学楼"}],"004":[{"id":{"campusNumber":"004","teachingBuildingNumber":"A座教学楼"},"remark":"","teachingBuildingName":"A座教学楼"},{"id":{"campusNumber":"004","teachingBuildingNumber":"C座教学楼"},"remark":"","teachingBuildingName":"C座教学楼"}],"014":[{"id":{"campusNumber":"014","teachingBuildingNumber":"体育教学"},"remark":"","teachingBuildingName":"体育教学"}],"011":[{"id":{"campusNumber":"011","teachingBuildingNumber":"第六教学楼"},"remark":"","teachingBuildingName":"第六教学楼"},{"id":{"campusNumber":"011","teachingBuildingNumber":"第五教学楼"},"remark":"","teachingBuildingName":"第五教学楼"},{"id":{"campusNumber":"011","teachingBuildingNumber":"运动场"},"remark":"","teachingBuildingName":"运动场"},{"id":{"campusNumber":"011","teachingBuildingNumber":"第三教学楼"},"remark":"","teachingBuildingName":"第三教学楼"},{"id":{"campusNumber":"011","teachingBuildingNumber":"第四教学楼"},"remark":"","teachingBuildingName":"第四教学楼"},{"id":{"campusNumber":"011","teachingBuildingNumber":"礼堂"},"remark":"","teachingBuildingName":"礼堂"}],"012":[{"id":{"campusNumber":"012","teachingBuildingNumber":"第六教学楼"},"remark":"","teachingBuildingName":"第六教学楼"},{"id":{"campusNumber":"012","teachingBuildingNumber":"第五教学楼"},"remark":"","teachingBuildingName":"第五教学楼"},{"id":{"campusNumber":"012","teachingBuildingNumber":"第四教学楼"},"remark":"","teachingBuildingName":"第四教学楼"},{"id":{"campusNumber":"012","teachingBuildingNumber":"运动场"},"remark":"","teachingBuildingName":"运动场"},{"id":{"campusNumber":"012","teachingBuildingNumber":"礼堂"},"remark":"","teachingBuildingName":"礼堂"},{"id":{"campusNumber":"012","teachingBuildingNumber":"第三教学楼"},"remark":"","teachingBuildingName":"第三教学楼"},{"id":{"campusNumber":"012","teachingBuildingNumber":"体育教学"},"remark":"","teachingBuildingName":"体育教学"}],"007":[{"id":{"campusNumber":"007","teachingBuildingNumber":"F106(新)"},"remark":"","teachingBuildingName":"第六教学楼（新）"},{"id":{"campusNumber":"007","teachingBuildingNumber":"体育教学"},"remark":"","teachingBuildingName":"体育教学"},{"id":{"campusNumber":"007","teachingBuildingNumber":"青春讲堂"},"remark":"","teachingBuildingName":"青春讲堂"},{"id":{"campusNumber":"007","teachingBuildingNumber":"玻璃教室"},"remark":"","teachingBuildingName":"玻璃教室"},{"id":{"campusNumber":"007","teachingBuildingNumber":"艺术中心"},"remark":"","teachingBuildingName":"艺术中心"},{"id":{"campusNumber":"007","teachingBuildingNumber":"F106"},"remark":"","teachingBuildingName":"实验楼"},{"id":{"campusNumber":"007","teachingBuildingNumber":"F105"},"remark":"","teachingBuildingName":"第五教学楼"},{"id":{"campusNumber":"007","teachingBuildingNumber":"F104"},"remark":"","teachingBuildingName":"第四教学楼"},{"id":{"campusNumber":"007","teachingBuildingNumber":"F101"},"remark":"","teachingBuildingName":"第一教学楼"},{"id":{"campusNumber":"007","teachingBuildingNumber":"F102"},"remark":"","teachingBuildingName":"第二教学楼"},{"id":{"campusNumber":"007","teachingBuildingNumber":"F103"},"remark":"","teachingBuildingName":"第三教学楼"},{"id":{"campusNumber":"007","teachingBuildingNumber":"F107"},"remark":"","teachingBuildingName":"第七教学楼"}],"015":[{"id":{"campusNumber":"015","teachingBuildingNumber":"体育教学"},"remark":"","teachingBuildingName":"体育教学"},{"id":{"campusNumber":"015","teachingBuildingNumber":"第二教学楼"},"remark":"","teachingBuildingName":"第二教学楼"},{"id":{"campusNumber":"015","teachingBuildingNumber":"第一教学楼"},"remark":"","teachingBuildingName":"第一教学楼"}]}]';

			$(function(){

				var xqcont = "";

				if(false){

					xqcont += '<h3 class="alert alert-danger" ><button type="button" class="close" data-dismiss="alert"><i class="ace-icon fa fa-times"></i></button><strong style="font-size:18px;">注：仅用于查询东区主楼、一教、二教、三教和西区新教、旧教、农学楼的本科生空闲教室。</strong></h3>';

				}

				$.each(eval("("+xqList+")"),function(i,v){

					var val = v.campusNumber + "_n";

					if(v.campusNumber==xqh){

						xqcont += "<h4 class='header smaller lighter grey'>"+v.campusName+"(<i class='glyphicon glyphicon-map-marker'></i>当前所在校区)</h4>"+

							"<div class='col-xs-12' id='div-"+v.campusNumber+"' style='padding-bottom:20px;padding-left: 0px;'>"+

							"<input type='hidden' value='"+v.campusName+"' id='input-"+v.campusNumber+"'/>" +

							"<button type='button' class='btn btn-primary btn-round' style='border-width:1px;margin-right:10px;margin-bottom:10px;' onclick='goDetail(\""+val+"\",\""+v.campusName+"\");'>全部教学楼</button></div>";

					}else{

						xqcont += "<h4 class='header smaller lighter grey'>"+v.campusName+"</h4>"+

							"<div class='col-xs-12' id='div-"+v.campusNumber+"' style='padding-bottom:20px;padding-left: 0px;'>"+

							"<input type='hidden' value='"+v.campusName+"' id='input-"+v.campusNumber+"'/>" +

							"<button type='button' class='btn btn-primary btn-round' style='border-width:1px;margin-right:10px;margin-bottom:10px;' onclick='goDetail(\""+val+"\",\""+v.campusName+"\");'>全部教学楼</button></div>";

					}

				});

				

				$("#campus").html(xqcont);

				

				$.map(eval("("+buildings+")")[0],function(vv,ii){

					var bcont = "";

					var xqdiv = "div-"+ii;

					$.each(vv,function(iii,vvv){

						var val = vvv.id.campusNumber + "_" + vvv.id.teachingBuildingNumber;

						bcont += "<button type='button' class='btn btn-white btn-round' style='border-width:1px;margin-right:10px;margin-bottom:10px;' onclick='goDetail(\""+val+"\",\""+$("#input-"+vvv.id.campusNumber).val()+"\");'>"+vvv.teachingBuildingName+"</button>";

					});

					$("#"+xqdiv).append(bcont);

				});

				

				$.each($("div[id^=div-]"),function(i,v){

					var btnLen = $(this).find("button").length;

					if(btnLen==1){

						$(this).find("button").addClass("disabled");

					}

				});

			});

			

			//跳详情

			function goDetail(p,xqm){

				var tform = document.createElement("form");

				var tinput = document.createElement("input");

				var tinput2 = document.createElement("input");

				tform.action = "/student/teachingResources/freeClassroom/today";

				tform.method = "post";

				tform.name = "tform";

				

				tinput.type = "hidden";

				tinput.value = p;

				tinput.name = "position";

				tinput2.type = "hidden";

				tinput2.value = xqm;

				tinput2.name = "xqm";

				

				tform.appendChild(tinput);

				tform.appendChild(tinput2);

				document.getElementById("campus").appendChild(tform);

				document.tform.submit();

			}