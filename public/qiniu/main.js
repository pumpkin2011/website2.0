/*global Qiniu */
/*global plupload */

$(function() {
	uploader = Qiniu.uploader({
  	runtimes: 'html5,flash,html4',    //上传模式,依次退化
    browse_button: 'upload',       //上传选择的点选按钮，**必需**
    uptoken_url: '/qiniu/token',
		unique_names: true,
    domain: 'http://7xq1xj.com1.z0.glb.clouddn.com/',
    // container: 'container',           //上传区域DOM ID，默认是browser_button的父元素，
    max_file_size: '5mb',           //最大文件体积限制
    // flash_swf_url: 'js/plupload/Moxie.swf',  //引入flash,相对路径
		flash_swf_url: '/uploader.swf',
    max_retries: 3,                   //上传失败最大重试次数
    dragdrop: true,                   //开启可拖曳上传
    drop_element: 'container',        //拖曳上传区域元素的ID，拖曳文件或文件夹后可触发上传
    chunk_size: '4mb',                //分块上传时，每片的体积
    auto_start: true,                 //选择文件后自动上传，若关闭需要自己绑定事件触发上传
    init: {
			'FilesAdded': function(up, files) {
			  plupload.each(files, function(file) {
			  	// alert("文件添加进队列后,处理相关的事情");
			  });
			},
      'BeforeUpload': function(up, file) {
   			// alert("每个文件上传前,处理相关的事情");
      },
      'UploadProgress': function(up, file) {
				// alert("每个文件上传时,处理相关的事情");
      },
      'FileUploaded': function(up, file, info) {
				// 每个文件上传成功后,处理相关的事情
				// 其中 info 是文件上传成功后，服务端返回的json，形式如
				// {
				//    "hash": "Fh8xVqod2MQ1mocfI4S4KpRL6D98",
				//    "key": "gogopher.jpg"
				//  }
				// 参考http://developer.qiniu.com/docs/v6/api/overview/up/response/simple-response.html
				var domain = up.getOption('domain');
				var res = $.parseJSON(info);
				var sourceLink = domain + res.key;
				$('#image_text').val(sourceLink)
				$('#upload').prop('src', sourceLink)
      },
      'Error': function(up, err, errTip) {
				alert(errTip);
      }
	  }
	});

})
