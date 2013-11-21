script "Improved Guild Trainer";
notify rlbond86;


boolean debug = false;
void debugPrint(string s)
{
    if (debug)
        print(s);
}

record SkillInfo
{
    int mpCost;
    int numTurns;
    string type;
    string effectText;
};


boolean isVariableEffect(string it)
{
	string s = string_modifier(it, "Modifiers"); // get list of modifiers
	matcher m = create_matcher("([^, :][^,:]*): \\[([^\\]]*)\\]", s); // find variable modifier
    return find(m);
}


string getEffect(string url, string name)
{
    string txt = visit_url(url);
    matcher m = create_matcher("<font color=blue[^>]*><b>(.*?)</b></font></center>", txt);
    if (find(m))
    {
        string s = group(m,1);
        if (isVariableEffect(name))
            s += " <i>(Variable)</i>";
        return s;
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
        string mp = group(effectMatcher, 2);
        if (mp == "N/A")
            s.mpCost = -1;
        else
            s.mpCost = to_int(mp);
        s.effectText = getEffect(group(effectMatcher, 3), group(effectMatcher, 4));
        matcher m = create_matcher("\\((\\d+) Adventures\\)", txt);
        if (find(m))
            s.numTurns = to_int(m.group(1));
        else
            s.numTurns = -1;
        return s;
    }
    matcher blueTextMatcher = create_matcher("(?s)<b>Type:</b>\\s*([^<]+)<.*MP Cost:</b>\\s*(\\d+|N/A).*<font color=blue[^>]*><b>(.*?)</b></font></center>", txt);
    if (find(blueTextMatcher))
    {
        debugPrint("Found blue text.");
        s.type = group(blueTextMatcher, 1);
        string mp = group(blueTextMatcher, 2);
        if (mp == "N/A")
            s.mpCost = -1;
        else
            s.mpCost = to_int(mp);
        s.effectText = group(blueTextMatcher, 3);
        s.numTurns = -1;
        return s;
    }
    matcher simpleMatcher = create_matcher("(?s)<b>Type:</b>\\s*([^<]+)<.*MP Cost:</b>\\s*(\\d+|N/A).*<blockquote class=small>([^<]+)<", txt);
    if (find(simpleMatcher))
    {
        debugPrint("Found simple match");
        s.type = group(simpleMatcher, 1);
        string mp = group(simpleMatcher, 2);
        if (mp == "N/A")
            s.mpCost = -1;
        else
            s.mpCost = to_int(mp);
        s.effectText = group(simpleMatcher, 3);
        s.numTurns = -2;
        return s;
    }
    debugPrint("Failed to match.");
    s.type = "?";
    s.mpCost = -1;
    s.numTurns = -1;
    s.effectText = "?";
    return s;
}


string getSkillText(int number)
{
    static string[int] skillMap;
    if (skillMap contains number)
        return skillMap[number];

    SkillInfo s = getSkillInfo(number);
    string st = s.type;
    if (s.mpCost >= 0)
    {
        if (s.numTurns >= 0)
            st += " (" + s.mpCost + " MP / " + s.numTurns + " adv.): ";
        else
            st += " (" + s.mpCost + " MP): ";
    }
    else
        st += ": ";
    st +=  s.effectText;
    st = replace_string(st, "<br>", ", ");
    if (char_at(st, length(st)-2) == ",")
        st = substring(st, 0, length(st)-2);
    if (s.numTurns == -2)
        st = "<font size=1><span style=\"max-width:300px; width:300px;\">" + st + "</span></font>";
    skillMap[number] = st;
    return st;
}


void main()
{
    if (form_field("place") != "trainer")
        if (form_field("action") != "buyskill")
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