// Filename: add_tail.js
// Author: Colin
// Date: 2016/06/02
// Based on the script by KUANG Qi: http://kuangqi.me/tricks/append-a-copyright-info-after-every-post/

// Add a tail to every post from tail.md
// Great for adding copyright info

var fs = require('fs');

hexo.extend.filter.register('before_post_render', function(data){
	if(data.copyright == false) return data;
	
	// Add seperate line
	data.content += '\n___\n';
	
	// Try to read tail.md
	try {
		var file_content = fs.readFileSync('tail.md');
		if(file_content && data.content.length > 50) 
		{
			data.content += file_content;
		}
	} catch (err) {
		if (err.code !== 'ENOENT') throw err;
		
		// No process for ENOENT error
	}

	return data;
});