package org.socialbiz.cog;

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONObject;

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
        JSONObject peopleList = new JSONObject();
        for (String onePerson : getPeople()){
            String name = onePerson;
            int val = 3;
            int pos = onePerson.lastIndexOf(":");
            if (pos>0) {
                name = onePerson.substring(0,pos);
                val = DOMFace.safeConvertInt(onePerson.substring(pos+1));
                if (val<1 || val > 5) {
                    val = 3;
                }
            }
            peopleList.put(name, val);
        }
        proposalInfo.put("people",  peopleList);
        return proposalInfo;
    }

    public void updateFromJSON(JSONObject input) throws Exception {
        if (input.has("proposedTime")) {
            setProposedTime(input.getLong("proposedTime"));
        }
        if (input.has("people")) {
            JSONObject peopleList = input.getJSONObject("people");
            List<String> res = new ArrayList<String>();
            for (String key : peopleList.keySet()) {
                int val = peopleList.getInt(key);
                res.add(key + ":" + val);
            }
            setPeople(res);
        }
    }

}
