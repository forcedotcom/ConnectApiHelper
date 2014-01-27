ConnectApiHelper
================

`ConnectApiHelper` is a class that makes it easier to post Chatter @-mentions with Apex code. If you want to mention someone in a post that says: *Hey there @Jane Doe, how are you?*, you can do it in one line like this:

    ConnectApi.FeedItem fi = ConnectApiHelper.postFeedItemWithMentions(null, 'me', 'Hey there {005D00000015tjz}, how are you?');

... instead of this:

    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = 'Hey there ';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
    mentionSegment.id = '005D00000015tjz'; // The ID of the user to mention.
    messageInput.messageSegments.add(mentionSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = ', how are you?';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;

    ConnectApi.FeedItem fi = ConnectApi.ChatterFeeds.postFeedItem(null, ConnectApi.FeedType.News, 'me', input, null);

Installation
------------

Just copy the `ConnectApiHelper` class to your Salesforce org. The methods to use are `ConnectApiHelper.postFeedItemWithMentions` and `ConnectApiHelper.postCommentWithMentions` and the parameters and formatting syntax are described in the method comments. You can also refer to the `ConnectApiHelperTest` class for more examples.
