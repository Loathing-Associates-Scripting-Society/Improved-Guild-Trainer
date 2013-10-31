
boolean debug = false;
void debugPrint(string s)
{
    if (debug)
        print(s);
}

record SkillInfo
{
    string cost;
    string type;
    string effectText;
};


string getEffect(string url)
{
    string txt = visit_url(url);
    matcher m = create_matcher("<font color=blue[^>]*><b>(.*?)</b></font></center>", txt);
    if (find(m))
    {
        return group(m,1);
    }
    return "";
}



SkillInfo getSkillInfo(int number)
{
    string txt = visit_url("desc_skill.php?whichskill=" + number + "&self=true");
    SkillInfo s;
    matcher effectMatcher = create_matcher("<b>Type:</b>\\s*([^<]+)<.*MP Cost:</b>\\s*(\\d+|N/A).*Gives Effect: <b><a.*?href=\"(desc_[^\"]+)\">([^<]+)</a>", txt);
    if (find(effectMatcher))
    {
        debugPrint("Matched skill to an effect");
        s.type = group(effectMatcher, 1);
        s.cost = group(effectMatcher, 2);
        s.effectText = getEffect(group(effectMatcher, 3));
        return s;
    }
    matcher blueTextMatcher = create_matcher("(?s)<b>Type:</b>\\s*([^<]+)<.*MP Cost:</b>\\s*(\\d+|N/A).*<font color=blue[^>]*><b>(.*?)</b></font></center>", txt);
    if (find(blueTextMatcher))
    {
        debugPrint("Found blue text.");
        s.type = group(blueTextMatcher, 1);
        s.cost = group(blueTextMatcher, 2);
        s.effectText = group(blueTextMatcher, 3);
        return s;
    }
    matcher simpleMatcher = create_matcher("(?s)<b>Type:</b>\s*([^<]+)<.*MP Cost:</b>\s*(\d+|N/A).*<blockquote class=small>([^<]+)<", txt);
    if (find(simpleMatcher))
    {
        debugPrint("Found simple match");
        s.type = group(simpleMatcher, 1);
        s.cost = group(simpleMatcher, 2);
        s.effectText = group(simpleMatcher, 3);
        return s;
    }
    debugPrint("Failed to match.");
    s.type = "?";
    s.cost = "?";
    s.effectText = "?";
    return s;
}


string getSkillText(int number)
{
    static string[int] skillMap;
    if (skillMap contains number)
        return skillMap[number];

    SkillInfo s = getSkillInfo(number);
    string st = s.type + " (" + s.cost + "): " + s.effectText;
    st = replace_string(st, "<br>", ", ");
    if (char_at(st, length(st)-2) == ",")
        st = substring(st, 0, length(st)-2);
    skillMap[number] = st;
    return st;
}


void main()
{
    if (form_field("place") != "trainer")
        return;

    string txt = visit_url();
    buffer out;
    matcher m = create_matcher("<b><a onClick='javascript:poop\\(\"desc_skill\\.php\\?whichskill=(\\d+)&self=true\",\"skill\", \\d+, \\d+\\)'>([^<]+)</a></b>&nbsp;&nbsp;&nbsp;", txt);
    while (find(m))
    {
        debugPrint("Found skill " + group(m, 2));
        string skillNumber = group(m, 1);
        string skillName = group(m, 2);
        string st = getSkillText(to_int(skillNumber));
        append_replacement(m, out, "<br>" + m.group() + "<br><font color=blue size=2><b>" + st + "</b></font>");
    }
    append_tail(m, out);
    write(out);
}    