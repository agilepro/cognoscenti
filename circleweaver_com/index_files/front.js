jQuery(document).ready(function(o){function t(t){t.preventDefault();var a=o(this).data("popup"),c=o(this).find("a").attr("href"),n=a.width,e=a.height,l="toolbar=0,scrollbars=1, location=0, width="+n+",height="+e+",left="+(o(window).width()-n)/2+",top="+(o(window).height()-e)/2;window.open(c,"mb-social-share-window",l).focus(),mbSocialTrack()}function a(t,a){var c=mb_ajax.ajaxurl,n=a.share_url,e=a.network,l=a.collection_id,a=(a.nonce,{block_name:"social",block_action:"ajax_get_count",action:"mbpro_collection_block_front",collection_id:l,collection_type:"social",block_data:{share_url:n,network:e}});o.ajax({type:"POST",url:c,data:a,success:function(a){!function(t,a){var c=o.parseJSON(t),n=o(a).data("onload"),e=parseInt(n.count_threshold),l=parseInt(c.data.count);if(l>=e){var i=n.text,r=n.text2;i=i.replace("{count}",l),i=i.replace("{c}",l),r=r.replace("{count}",l),r=r.replace("{c}",l),o(a).find(".mb-text").html(i),o(a).find(".mb-text2").html(r)}}(a,t)}})}mbSocialTrack=function(o){},"function"==typeof o?(o(".maxcollection .mb-collection-item[data-popup]").on("click",t),o(".maxcollection .mb-collection-item[data-onload]").each(function(){var t=o(this).parents(".maxcollection").data("collection"),c=o(this).data("onload");c.collection_id=t,a(this,c)})):console.log("Maxbuttons : Jquery load conflict.")});