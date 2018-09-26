/*
Copyright (c) 2018, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 *
 * Unit tests for ConnectApiHelper.
 *
 * This class works with API version 31.0 and earlier. There are separate classes
 * that work with a) v32.0 to v34.0, and b) v35.0 and higher.
 *
 * See https://github.com/forcedotcom/ConnectApiHelper for more information.
 *
 */


@IsTest(SeeAllData=true)
public class ConnectApiHelperTest {

    @IsTest(SeeAllData=true)
    static void testInvalidMentionType() {
        Boolean exceptionThrown = false;
        try {
            ConnectApiHelper.postFeedItemWithMentions(null, 'me', '{001x00000000D7m}'); // not a group or user id
        }
        catch (ConnectApi.ConnectApiException e) {
            System.assertEquals('Only user and group IDs may be used in inline mentions.', e.getMessage());
            exceptionThrown = true;
        }
        System.assert(exceptionThrown);
    }

    @IsTest(SeeAllData=true)
    static void testNullString() {
        Boolean exceptionThrown = false;
        try {
            List<ConnectApi.MessageSegmentInput> segments = ConnectApiHelper.getMessageSegmentInputs(null);
        }
        catch (ConnectApiHelper.InvalidParameterException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown);
    }

    @IsTest(SeeAllData=true)
    static void testEmptyString() {
        List<ConnectApi.MessageSegmentInput> segments = ConnectApiHelper.getMessageSegmentInputs('');
        System.assertEquals(0, segments.size());
    }

    @IsTest(SeeAllData=true)
    static void testNoMentions() {
        String text = 'hey there';
        List<ConnectApi.MessageSegmentInput> segments = ConnectApiHelper.getMessageSegmentInputs(text);

        System.assertEquals(1, segments.size());
        System.assert(segments.get(0) instanceof ConnectApi.TextSegmentInput);
        ConnectApi.TextSegmentInput textSegment = (ConnectApi.TextSegmentInput) segments.get(0);
        System.assertEquals(text, textSegment.text);
    }

    @IsTest(SeeAllData=true)
    static void testMentionOnly() {
        String mentionId = '005x0000000URNP';
        String text = '{' + mentionId + '}';
        List<ConnectApi.MessageSegmentInput> segments = ConnectApiHelper.getMessageSegmentInputs(text);

        System.assertEquals(1, segments.size());
        System.assert(segments.get(0) instanceof ConnectApi.MentionSegmentInput);
        ConnectApi.MentionSegmentInput mentionSegment = (ConnectApi.MentionSegmentInput) segments.get(0);
        System.assertEquals(mentionId, mentionSegment.id);
    }

    @IsTest(SeeAllData=true)
    static void testLeadingMention() {
        String mentionId = '005x0000000URNPzzz';
        String restOfMessage = ' - how are you?';
        String text = '{' + mentionId + '}' + restOfMessage;
        List<ConnectApi.MessageSegmentInput> segments = ConnectApiHelper.getMessageSegmentInputs(text);

        System.assertEquals(2, segments.size());
        System.assert(segments.get(0) instanceof ConnectApi.MentionSegmentInput);
        System.assert(segments.get(1) instanceof ConnectApi.TextSegmentInput);

        ConnectApi.MentionSegmentInput mentionSegment = (ConnectApi.MentionSegmentInput) segments.get(0);
        System.assertEquals(mentionId, mentionSegment.id);

        ConnectApi.TextSegmentInput textSegment = (ConnectApi.TextSegmentInput) segments.get(1);
        System.assertEquals(restOfMessage, textSegment.text);
    }

    @IsTest(SeeAllData=true)
    static void testTrailingMention() {
        String restOfMessage = 'Here we go: ';
        String mentionId = '005x0000000URNPzzz';
        String text = restOfMessage + '{' + mentionId + '}';
        List<ConnectApi.MessageSegmentInput> segments = ConnectApiHelper.getMessageSegmentInputs(text);

        System.assertEquals(2, segments.size());
        System.assert(segments.get(0) instanceof ConnectApi.TextSegmentInput);
        System.assert(segments.get(1) instanceof ConnectApi.MentionSegmentInput);

        ConnectApi.TextSegmentInput textSegment = (ConnectApi.TextSegmentInput) segments.get(0);
        System.assertEquals(restOfMessage, textSegment.text);

        ConnectApi.MentionSegmentInput mentionSegment = (ConnectApi.MentionSegmentInput) segments.get(1);
        System.assertEquals(mentionId, mentionSegment.id);
    }

    @IsTest(SeeAllData=true)
    static void testAdjacentMentions() {
        String mentionId  = '005x0000000URNPzzz';
        String mentionId2 = '0F9x00000000D7m';
        String text = '{' + mentionId + '}' + '{' + mentionId2 + '}';
        List<ConnectApi.MessageSegmentInput> segments = ConnectApiHelper.getMessageSegmentInputs(text);

        System.assertEquals(2, segments.size());
        System.assert(segments.get(0) instanceof ConnectApi.MentionSegmentInput);
        System.assert(segments.get(1) instanceof ConnectApi.MentionSegmentInput);

        ConnectApi.MentionSegmentInput mentionSegment = (ConnectApi.MentionSegmentInput) segments.get(0);
        System.assertEquals(mentionId, mentionSegment.id);

        ConnectApi.MentionSegmentInput mentionSegment2 = (ConnectApi.MentionSegmentInput) segments.get(1);
        System.assertEquals(mentionId2, mentionSegment2.id);
    }

    @IsTest(SeeAllData=true)
    static void testLinkAndHashtagParsing() {
        // The test string is: #Yolo: http://salesforce.com, {005} {005x0000000URNPzzz} test.
        //                     [   ][][                   ][      ][                  ][    ]
        //                     0    1 2                    3       4                   5
        // 0 = hashtag
        // 1 = text1
        // 2 = link
        // 3 = text2
        // 4 = mention
        // 5 = text3

        String hashtag = 'Yolo';
        String text1 = ': ';
        String link = 'http://salesforce.com';
        String text2 = ', {005} ';
        String mentionId = UserInfo.getUserId();
        String text3 = ' test.';
        String text = '#' + hashtag + text1 + link + text2 + '{' + mentionId + '}' + text3;

        ConnectApi.FeedItem fi = ConnectApiHelper.postFeedItemWithMentions(null, 'me', text);

        List<ConnectApi.MessageSegment> segments = fi.body.messageSegments;

        System.assertEquals(6, segments.size());
        System.assert(segments.get(0) instanceof ConnectApi.HashtagSegment);
        System.assert(segments.get(1) instanceof ConnectApi.TextSegment);
        System.assert(segments.get(2) instanceof ConnectApi.LinkSegment);
        System.assert(segments.get(3) instanceof ConnectApi.TextSegment);
        System.assert(segments.get(4) instanceof ConnectApi.MentionSegment);
        System.assert(segments.get(5) instanceof ConnectApi.TextSegment);

        ConnectApi.HashtagSegment hashtagSegment = (ConnectApi.HashtagSegment) segments.get(0);
        System.assertEquals(hashtag, hashtagSegment.tag);

        ConnectApi.TextSegment textSegment1 = (ConnectApi.TextSegment) segments.get(1);
        System.assertEquals(text1, textSegment1.text);

        ConnectApi.LinkSegment linkSegment = (ConnectApi.LinkSegment) segments.get(2);
        System.assertEquals(link, linkSegment.url);

        ConnectApi.TextSegment textSegment2 = (ConnectApi.TextSegment) segments.get(3);
        System.assertEquals(text2, textSegment2.text);

        ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) segments.get(4);
        System.assertEquals(mentionId, mentionSegment.record.id);

        ConnectApi.TextSegment textSegment3 = (ConnectApi.TextSegment) segments.get(5);
        System.assertEquals(text3, textSegment3.text);
    }

    @IsTest(SeeAllData=true)
    static void testMentionInComment() {
        ConnectApi.FeedItem fi = ConnectApi.ChatterFeeds.postFeedItem(null, ConnectApi.FeedType.News, 'me', 'hi');
        String mentionId = UserInfo.getUserId();
        String text = '{' + mentionId + '}';
        ConnectApi.Comment comment = ConnectApiHelper.postCommentWithMentions(null, fi.id, text);

        List<ConnectApi.MessageSegment> segments = comment.body.messageSegments;
        System.assertEquals(1, segments.size());
        System.assert(segments.get(0) instanceof ConnectApi.MentionSegment);
        ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) segments.get(0);
        System.assertEquals(mentionId, mentionSegment.record.id);
    }

}
