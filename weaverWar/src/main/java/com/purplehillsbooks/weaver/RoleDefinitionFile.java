/*
 * Copyright 2025 Keith D Swenson
 *
 */

package com.purplehillsbooks.weaver;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.weaver.exception.WeaverException;

/**
* this is just a file that contains a bunch of role definitions
*/
public class RoleDefinitionFile {
    
    public List<RoleDefinition> roleDefs = new ArrayList<>();

    private RoleDefinitionFile() {}

    public static RoleDefinitionFile loadRoleDefs(File filePath) throws Exception {
        RoleDefinitionFile contents = JsonUtil.loadJsonFile(filePath, RoleDefinitionFile.class);
        for (RoleDefinition rd : contents.roleDefs) {
            if (rd.name == null) {
                rd.name = rd.symbol;
            }
        }
        return contents;
    }

    public void saveRoleDefs(File filePath) throws Exception {
        JsonUtil.saveJsonFile(filePath, this);
    }

    public JSONArray getJSON() throws Exception {
        JSONArray ja = new JSONArray();
        for (RoleDefinition rd : roleDefs) {
            ja.put( rd.getJSON() );
        }
        return ja;
    }

    public RoleDefinition findRoleDef(String symbol) {
        for (RoleDefinition rd : roleDefs) {
            if (symbol.equals(rd.symbol)) {
                return rd.getClone();
            }
        }
        return null;
    }

    public RoleDefinition findRoleDefOrFail(String symbol) throws WeaverException {
        RoleDefinition rd = findRoleDef(symbol);
        if (rd == null) {
            throw WeaverException.newBasic("There is no role definition named (%s)", symbol);
        }
        return rd;
    }

    public RoleDefinition findOrCreateRoleDef(String symbol) {
        for (RoleDefinition rd : roleDefs) {
            if (symbol.equals(rd.symbol)) {
                return rd;
            }
        }
        RoleDefinition newOne = new RoleDefinition();
        newOne.symbol = symbol;
        newOne.name = symbol;
        roleDefs.add(newOne);
        return newOne;
    }    
}
