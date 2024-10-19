package com.purplehillsbooks.weaver.mail;

import java.io.File;
import java.io.IOException;
import com.purplehillsbooks.streams.MemFile;
import com.purplehillsbooks.weaver.AuthRequest;
import com.purplehillsbooks.weaver.exception.WeaverException;
import com.x5.template.providers.TemplateProvider;

public class TemplateProviderWeaver extends TemplateProvider {

    AuthRequest ar;
    
    public TemplateProviderWeaver(AuthRequest _ar) throws Exception {
        ar = _ar;
    }
    
    /**
     * no idea what this does, however some of the sample classes return 'include' so doing that here
     */
    @Override
    public String getProtocol() {
        return "include";
    }
    
    @Override
    public boolean provides(String templateName) {
        try {
            //System.out.println("TemplateProviderWeaver.provides request for template="+templateName);
            String nameWithExtension = templateName + ".chtml";
            File templateFile = ar.findChunkTemplate(nameWithExtension);
            return templateFile.exists();
        }
        catch (Exception e) {
            System.out.println("TemplateProviderWeaver.provides EXCEPTION for "+templateName);
            e.printStackTrace(System.out);
        }
        //System.out.println("TemplateProviderWeaver.provides returned FALSE for template="+templateName);
        return false;
    }
    
    
    @Override
    public String fetch(String templateName) {
        System.out.println("TemplateProviderWeaver.fetch called for template="+templateName);
        //have to defeat the cache because different sites have different 
        //versions of the same template, this forces load each time
        super.clearCache();
        return super.fetch(templateName);
    }

    /**
     * Apparently this method is to read the template file and return
     * the contents as a string.   
     * It is apparently given the full file name "MyTemplate.chtml"
     */
    @Override
    public String loadContainerDoc(String templateName) throws IOException {
        try {
            //System.out.println("TemplateProviderWeaver.loadContainerDoc called for template="+templateName);
            if (!templateName.endsWith(".chtml")) {
                throw WeaverException.newBasic("Something is wrong, the file should end with .chtml");
            }
            File templateFile = ar.findChunkTemplate(templateName);
            //System.out.println("TemplateProviderWeaver found template="+templateFile.getAbsolutePath());
            MemFile mf = new MemFile();
            mf.fillWithFile(templateFile);
            return mf.toString();
        }
        catch (Exception e) {
            
            //I am not sure that this exception is not swallowed someplace, so print it here.
            System.out.println("TemplateProviderWeaver.loadContainerDoc EXCEPTION for "+templateName);
            e.printStackTrace(System.out);
            throw new IOException("Error in TemplateProviderWeaver reading of template: "+templateName, e);
        }
    }

}
