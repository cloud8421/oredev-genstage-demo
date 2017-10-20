var data = $('.session-day')
  .map(function(i, day) {
    var dayNumber = i + 1;

    return $('.session-slot', day)
      .map(function(j, s) {
        return {speaker: $('.speaker', s).text(),
                day: dayNumber,
                title: $('.title', s).text(),
                room: $('.room', s).text(),
                starts_at: $('.time', s).text()}
      }).toArray();
  })
  .toArray();
