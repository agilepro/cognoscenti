package org.socialbiz.cog;

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

/**
 * A meeting can have a set of proposed times.  People can then indicate when they want to
 * meet.  From that, you can set the meeting time
 */
public class MeetingProposeTime extends DOMFace {


    public MeetingProposeTime(Document doc, Element ele, DOMFace p) throws Exception {
        super(doc, ele, p);

    }

    public long getProposedTime() {
        return getAttributeLong("proposedTime");
    }
    public void setProposedTime(long timeVal) {
        setAttributeLong("proposedTime", timeVal);
    }

    public List<String> getPeople() {
        return getVector("people");
    }
    public void setPeople(List<String> timeVal) {
        setVector("people", timeVal);
    }

    /**
     * A small object suitable for lists of meetings
     */
    public JSONObject getJSON() throws Exception {
        JSONObject proposalInfo = new JSONObject();

        proposalInfo.put("proposedTime",  getProposedTime());
        JSONArray peopleList = new JSONArray();
        for (String onePerson : getPeople()){
            AddressListEntry ale = new AddressListEntry(onePerson);
            JSONObject sub = ale.getJSON();
            peopleList.put(sub);
        }
        proposalInfo.put("people",  peopleList);
        return proposalInfo;
    }

    public void updateFromJSON(JSONObject input) throws Exception {
        if (input.has("proposedTime")) {
            setProposedTime(input.getLong("proposedTime"));
        }
        if (input.has("people")) {
            JSONArray peopleList = input.getJSONArray("people");
            List<String> res = new ArrayList<String>();
            for (int i=0; i<peopleList.length(); i++) {
                JSONObject one = peopleList.getJSONObject(i);
                if (one.has("udi")) {
                    res.add(one.getString("uid"));
                }
            }
            setPeople(res);
        }
    }

}
