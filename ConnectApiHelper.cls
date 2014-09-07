/**
 *
 * Helper class that makes it easier to post Chatter @-mentions with Apex code.
 * This class works with API version 32.0 and later. There is a separate class
 * that works with v31.0 and earlier.
 *
 * See https://github.com/alouie-sfdc/ConnectApiHelper for more information.
 *
 */

global class ConnectApiHelper {

    public class InvalidParameterException extends Exception {}

    /**
     * Posts a feed item with @-mentions using an @-mention formatting syntax.
     * 
     * @param communityId Use either the ID of a community, 'internal', or null.
     * @param subjectId The parent of the post. Can be a user ID, a group ID, or a record ID.
     * @param textWithMentions The text of the post. You can @-mention a user or group by using
     *                         the syntax {ID}, for example: 'Hello {005x0000000URNP}, have you
     *                         seen the group {0F9x00000000D7m}?' Links and hashtags will be
     *                         automatically parsed if provided.
     * @return The posted feed item.
     */
    public static ConnectApi.FeedElement postFeedItemWithMentions(String communityId, String subjectId, String textWithMentions) {

        if (textWithMentions == null || textWithMentions.trim().length() == 0) {
            throw new InvalidParameterException('The textWithMentions parameter must be non-empty.');
        }
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = getMessageSegmentInputs(textWithMentions);

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.subjectId = subjectId;
        
        return ConnectApi.ChatterFeeds.postFeedElement(communityId, input, null);
    }

    /**
     * Posts a comment with @-mentions using an @-mention formatting syntax.
     * 
     * @param communityId Use either the ID of a community, 'internal', or null.
     * @param feedItemId The ID of the feed item being commented on.
     * @param textWithMentions The text of the comment. You can @-mention a user or group by using
     *                         the syntax {ID}, for example: 'Hello {005x0000000URNP}, have you
     *                         seen the group {0F9x00000000D7m}?' Links and hashtags will be
     *                         automatically parsed if provided.
     * @return The posted comment.
     */
    public static ConnectApi.Comment postCommentWithMentions(String communityId, String feedItemId, String textWithMentions) {

        if (textWithMentions == null || textWithMentions.trim().length() == 0) {
            throw new InvalidParameterException('The textWithMentions parameter must be non-empty.');
        }
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = getMessageSegmentInputs(textWithMentions);

        ConnectApi.CommentInput input = new ConnectApi.CommentInput();
        input.body = messageInput;
        
        return ConnectApi.ChatterFeeds.postCommentToFeedElement(communityId, feedItemId, input, null);
    }

    public static List<ConnectApi.MessageSegmentInput> getMessageSegmentInputs(String inputText) {
        if (inputText == null) {
            throw new InvalidParameterException('The inputText parameter cannot be null.');
        }

        List<ConnectApi.MessageSegmentInput> messageSegmentInputs = new List<ConnectApi.MessageSegmentInput>();
        Integer strPos = 0;
        Pattern myPattern = Pattern.compile('\\{[a-zA-Z0-9]{15}\\}|\\{[a-zA-Z0-9]{18}\\}'); // Match a 15 or 18 character ID surrounded by {}.
        Matcher myMatcher = myPattern.matcher(inputText);
        
        while (myMatcher.find()) {
              String textSegment = inputText.substring(strPos, myMatcher.start());
              String mentionId = myMatcher.group();
              // Strip off the { and }.
              mentionId = mentionId.substring(1, mentionId.length() - 1);
              strPos = myMatcher.end();
              
              if (textSegment != null && textSegment.length() > 0) {
                  ConnectApi.TextSegmentInput textSegmentInput = makeTextSegmentInput(textSegment);
                  messageSegmentInputs.add(textSegmentInput);
              }
              
              ConnectApi.MentionSegmentInput mentionSegmentInput = makeMentionSegmentInput(mentionId);
              messageSegmentInputs.add(mentionSegmentInput);
        }

        // Take care of any text that comes after the last mention.
        if (strPos < inputText.length()) {
            String trailingText = inputText.substring(strPos, inputText.length());
            if (trailingText != null && trailingText.length() > 0) {
                ConnectApi.TextSegmentInput textSegmentInput = makeTextSegmentInput(trailingText);
                messageSegmentInputs.add(textSegmentInput);
            }
        }

        return messageSegmentInputs;
    }

    private static ConnectApi.TextSegmentInput makeTextSegmentInput(String text) {
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = text;
        return textSegment;
    }
    
    private static ConnectApi.MentionSegmentInput makeMentionSegmentInput(String mentionId) {
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = mentionId;
        return mentionSegment;
    }
    
}
