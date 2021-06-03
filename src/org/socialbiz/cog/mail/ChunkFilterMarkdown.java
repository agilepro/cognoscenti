package org.socialbiz.cog.mail;

import java.io.StringWriter;

import org.socialbiz.cog.AuthRequest;
import org.socialbiz.cog.WikiConverterBasic;

import com.x5.template.Chunk;
import com.x5.template.filters.BasicFilter;
import com.x5.template.filters.ChunkFilter;
import com.x5.template.filters.FilterArgs;

/**
  Markdown is a format used internally within Weaver for
  rich text format.  Markdown needs to be converted to 
  HTML when sent in an email message or other destinations.
  This filter converts a block of markdown text into a 
  block of HTML text.

 */
public class ChunkFilterMarkdown  extends BasicFilter implements ChunkFilter {
	AuthRequest dest;
	
    public ChunkFilterMarkdown() {
    }

    @Override
    public String transformText(Chunk chunk, String valueIn, FilterArgs args) {
    	StringWriter sw = new StringWriter();
    	try {
	    	WikiConverterBasic.writeWikiAsHtml(sw, valueIn);
    	}
    	catch (Exception e) {
    		sw.append("\n\n EXCEPTION \n\n");
    		sw.append(e.toString());
    	}
    	return sw.toString();
    }

    @Override
    public String getFilterName() {
        return "markdown";
    }
}