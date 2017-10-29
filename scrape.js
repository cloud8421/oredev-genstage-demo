// You can visit http://www.oredev.org/2017/sessions (at desktop viewport size) and paste
// this snippet to get a JSON string with the schedule data.

var data = $('.session-day')
  .map(function(i, day) {
    var dayNumber = i + 1;

    return $('.session-slot', day)
      .map(function(j, s) {
        var topics = s.className.split(" ")
          .filter(function(a) { return a.startsWith("Tag") })
          .map(function(topic) { return topic.replace("Tag", "") })
          .filter(function(a) { return a !== "" });

        return {speaker: $('.speaker', s).text(),
                day: dayNumber,
                title: $('.title', s).text(),
                topics: topics,
                room: $('.room', s).text(),
                starts_at: $('.time', s).text()}
      }).toArray();
  })
  .toArray();

JSON.stringify({docs: data});
