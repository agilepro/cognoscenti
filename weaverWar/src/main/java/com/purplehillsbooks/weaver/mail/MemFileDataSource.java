package com.purplehillsbooks.weaver.mail;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import jakarta.activation.DataSource;

import com.purplehillsbooks.streams.MemFile;

public class MemFileDataSource implements DataSource{
    private MemFile mf;
    private String contentType;
    private String name;

    public MemFileDataSource(MemFile _mf, String _name, String _contentType) {
        mf = _mf;
        contentType = _contentType;
        name = _name;
    }

    @Override
    public String getContentType() {
        return contentType;
    }

    @Override
    public InputStream getInputStream() throws IOException {
        return mf.getInputStream();
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public OutputStream getOutputStream() throws IOException {
        throw new IOException("getOutputStream is not implemented for this data source.");
    }


}
