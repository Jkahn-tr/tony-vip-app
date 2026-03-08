import Foundation
import SwiftUI

struct SampleData {

    static let contacts: [VIPContact] = [

        VIPContact(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Oprah Winfrey",
            role: "Media Executive & Philanthropist",
            organization: "OWN Network",
            avatarInitials: "OW",
            avatarColorHex: "8b5cf6",
            phone: "+1 (310) 555-0101",
            email: "oprah@own.com",
            relationshipHealth: .strong,
            tier: .inner,
            lastContactedAt: Calendar.current.date(byAdding: .day, value: -2, to: .now),
            notes: [
                ContactNote(id: UUID(), body: "Discussed potential collaboration on a documentary series around peak performance. Very interested. She mentioned wanting to feature Tony's UPW framework.", createdAt: Calendar.current.date(byAdding: .day, value: -2, to: .now)!, isPinned: true),
                ContactNote(id: UUID(), body: "Birthday: January 29th. Prefers text over email. Best time to reach: late morning PT.", createdAt: Calendar.current.date(byAdding: .month, value: -3, to: .now)!, isPinned: false),
            ],
            rpmProjects: [
                RPMReference(id: UUID(), projectName: "OWN Documentary", outcome: "Finalize concept and pitch outline", lastUpdated: .now, status: .active),
            ],
            pendingItems: [
                PendingItem(id: UUID(), title: "Send documentary concept deck", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now), isUrgent: true),
            ],
            tags: ["Media", "Philanthropy", "Documentary"],
            blazeContext: BlazeContext(
                summary: "Oprah last reached out 2 days ago about a potential documentary collaboration. She has strong interest in the UPW framework. Relationship is very warm — you've spoken 4 times in the past 90 days.",
                suggestedOpener: "Hey Oprah — putting together a quick concept doc for the documentary. Want to get on a call this week before I finalize it?",
                keyFacts: ["Met at Global Impact Summit 2019", "Co-sponsored Haiti relief fund", "Her team contact: Gail King +1 (310) 555-0102"],
                lastUpdated: .now
            )
        ),

        VIPContact(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Elon Musk",
            role: "CEO — Tesla, SpaceX, X",
            organization: "Tesla / SpaceX / X",
            avatarInitials: "EM",
            avatarColorHex: "0ea5e9",
            phone: nil,
            email: "elon@x.com",
            relationshipHealth: .good,
            tier: .vip,
            lastContactedAt: Calendar.current.date(byAdding: .day, value: -11, to: .now),
            notes: [
                ContactNote(id: UUID(), body: "Agreed to speak at Business Mastery 2027. Needs to confirm date by April. His EA is Jehn Balajadia.", createdAt: Calendar.current.date(byAdding: .day, value: -11, to: .now)!, isPinned: true),
            ],
            rpmProjects: [
                RPMReference(id: UUID(), projectName: "Business Mastery 2027 Speaker", outcome: "Confirm Elon as keynote — date lock by April 15", lastUpdated: .now, status: .pending),
            ],
            pendingItems: [
                PendingItem(id: UUID(), title: "Follow up on BM 2027 date confirmation", dueDate: Calendar.current.date(byAdding: .day, value: 7, to: .now), isUrgent: false),
            ],
            tags: ["Tech", "Speaker", "Business Mastery"],
            blazeContext: BlazeContext(
                summary: "Elon verbally committed to Business Mastery 2027 speaker slot 11 days ago. Follow-up is due. He communicates best via X DM or direct text. EA is Jehn Balajadia (+1 512 555 0103).",
                suggestedOpener: "Elon — circling back on BM 2027. We need to lock your date by April 15 so we can announce. Two options: Oct 14-16 or Nov 4-6. Which works?",
                keyFacts: ["BM 2027 spoken commitment — needs formal confirmation", "Prefers direct, short messages", "EA: Jehn Balajadia"],
                lastUpdated: .now
            )
        ),

        VIPContact(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Marc Benioff",
            role: "CEO — Salesforce",
            organization: "Salesforce",
            avatarInitials: "MB",
            avatarColorHex: "0284c7",
            phone: "+1 (415) 555-0103",
            email: "marc@salesforce.com",
            relationshipHealth: .strong,
            tier: .inner,
            lastContactedAt: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            notes: [
                ContactNote(id: UUID(), body: "Marc is interested in co-authoring a chapter in the next Tony book on conscious capitalism. Very aligned on philanthropy angle.", createdAt: Calendar.current.date(byAdding: .day, value: -5, to: .now)!, isPinned: true),
                ContactNote(id: UUID(), body: "Invited Tony to speak at Dreamforce 2026 — confirmed. September 15-17, San Francisco.", createdAt: Calendar.current.date(byAdding: .day, value: -30, to: .now)!, isPinned: false),
            ],
            rpmProjects: [
                RPMReference(id: UUID(), projectName: "Dreamforce 2026 Keynote", outcome: "Prep and deliver peak performance keynote", lastUpdated: .now, status: .active),
                RPMReference(id: UUID(), projectName: "Book Chapter — Conscious Capitalism", outcome: "Co-author chapter with Marc", lastUpdated: .now, status: .pending),
            ],
            pendingItems: [],
            tags: ["Tech", "Author", "Speaker", "Dreamforce"],
            blazeContext: BlazeContext(
                summary: "Marc is a strong relationship — 2 active collaborations. Dreamforce 2026 keynote confirmed September 15-17. Book chapter interest raised last week, needs a follow-up draft outline.",
                suggestedOpener: nil,
                keyFacts: ["Dreamforce keynote confirmed Sept 15-17 SF", "Co-author opportunity on conscious capitalism", "Met at Davos 2018"],
                lastUpdated: .now
            )
        ),

        VIPContact(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Arianna Huffington",
            role: "Founder — Thrive Global",
            organization: "Thrive Global",
            avatarInitials: "AH",
            avatarColorHex: "ec4899",
            phone: "+1 (212) 555-0104",
            email: "arianna@thriveglobal.com",
            relationshipHealth: .fading,
            tier: .vip,
            lastContactedAt: Calendar.current.date(byAdding: .day, value: -34, to: .now),
            notes: [
                ContactNote(id: UUID(), body: "Last spoke at the Well-being Summit. She wants to co-host a longevity retreat in 2027. Interest was strong but haven't followed up.", createdAt: Calendar.current.date(byAdding: .day, value: -34, to: .now)!, isPinned: true),
            ],
            rpmProjects: [
                RPMReference(id: UUID(), projectName: "Longevity Retreat 2027", outcome: "Co-design and co-host with Arianna", lastUpdated: .now, status: .pending),
            ],
            pendingItems: [
                PendingItem(id: UUID(), title: "Re-engage on longevity retreat concept — overdue", dueDate: Calendar.current.date(byAdding: .day, value: -4, to: .now), isUrgent: true),
            ],
            tags: ["Health", "Wellness", "Author"],
            blazeContext: BlazeContext(
                summary: "Relationship is fading — 34 days since last contact, which is unusual for this relationship. She raised a longevity retreat collaboration at the last meeting. This needs a re-engagement touch today.",
                suggestedOpener: "Arianna — been thinking about the longevity retreat idea you mentioned. I'm ready to put real structure around it. Can we get 20 minutes this week?",
                keyFacts: ["Thrive Global partnership potential", "Interest in longevity retreat 2027", "Last spoken at Well-being Summit"],
                lastUpdated: .now
            )
        ),

        VIPContact(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "Satya Nadella",
            role: "CEO — Microsoft",
            organization: "Microsoft",
            avatarInitials: "SN",
            avatarColorHex: "22c55e",
            phone: nil,
            email: "satyan@microsoft.com",
            relationshipHealth: .good,
            tier: .vip,
            lastContactedAt: Calendar.current.date(byAdding: .day, value: -18, to: .now),
            notes: [
                ContactNote(id: UUID(), body: "Satya connected Tony with Microsoft's AI team to explore integrating Copilot into Tony AI platform. Intro call went well.", createdAt: Calendar.current.date(byAdding: .day, value: -18, to: .now)!, isPinned: true),
            ],
            rpmProjects: [
                RPMReference(id: UUID(), projectName: "Microsoft AI Partnership", outcome: "Explore Copilot integration in Tony AI", lastUpdated: .now, status: .active),
            ],
            pendingItems: [
                PendingItem(id: UUID(), title: "Schedule technical follow-up with Microsoft AI team", dueDate: Calendar.current.date(byAdding: .day, value: 5, to: .now), isUrgent: false),
            ],
            tags: ["Tech", "AI", "Partnership"],
            blazeContext: BlazeContext(
                summary: "Satya made an intro to Microsoft's AI team 18 days ago. Technical follow-up call needs to be scheduled. Relationship is productive and growing.",
                suggestedOpener: "Satya — the Microsoft AI intro was incredibly valuable. We're ready to move into a technical evaluation. Would you connect me with the right person to schedule the next step?",
                keyFacts: ["Microsoft AI team intro completed", "Copilot x Tony AI potential integration", "Met at Fortune 500 CEO Summit"],
                lastUpdated: .now
            )
        ),

        VIPContact(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "Deepak Chopra",
            role: "Author & Wellness Leader",
            organization: "Chopra Foundation",
            avatarInitials: "DC",
            avatarColorHex: "f59e0b",
            phone: "+1 (858) 555-0106",
            email: "deepak@chopra.com",
            relationshipHealth: .cold,
            tier: .key,
            lastContactedAt: Calendar.current.date(byAdding: .day, value: -91, to: .now),
            notes: [
                ContactNote(id: UUID(), body: "Haven't spoken in 3 months. Last interaction was warm but nothing has happened since. Should loop him into the longevity retreat concept.", createdAt: Calendar.current.date(byAdding: .day, value: -91, to: .now)!, isPinned: false),
            ],
            rpmProjects: [],
            pendingItems: [
                PendingItem(id: UUID(), title: "Re-engage Deepak — 91 days cold", dueDate: .now, isUrgent: true),
            ],
            tags: ["Wellness", "Author", "Spirituality"],
            blazeContext: BlazeContext(
                summary: "91 days since last contact — this relationship has gone cold. Deepak is a natural fit for the longevity retreat collaboration with Arianna. A simple reconnection message could warm this quickly.",
                suggestedOpener: "Deepak — been too long. I'm working on something in the longevity space that I think you'd love to be part of. Can we connect this week?",
                keyFacts: ["90+ days no contact", "Natural fit for longevity retreat", "Best via text — responds quickly"],
                lastUpdated: .now
            )
        ),
    ]

    static let messages: [Message] = [
        // Oprah thread
        Message(id: UUID(), contactId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, body: "Tony, I've been thinking about our conversation at the summit. The idea of documenting your UPW process from the inside — I think it could be incredibly powerful.", isFromTony: false, sentAt: Calendar.current.date(byAdding: .hour, value: -50, to: .now)!, channel: .blaze, isRead: true),
        Message(id: UUID(), contactId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, body: "Oprah — this is exactly the kind of project I've wanted to do for years. Let me put together a concept doc and send it over by end of week.", isFromTony: true, sentAt: Calendar.current.date(byAdding: .hour, value: -48, to: .now)!, channel: .blaze, isRead: true),
        Message(id: UUID(), contactId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, body: "Perfect. I'll have my team block time the week of March 17. Looking forward to seeing what you put together. 🙏", isFromTony: false, sentAt: Calendar.current.date(byAdding: .hour, value: -47, to: .now)!, channel: .blaze, isRead: true),

        // Elon — unread
        Message(id: UUID(), contactId: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, body: "Tony — still down for BM 2027. Have your team send dates and I'll confirm. Wild year ahead.", isFromTony: false, sentAt: Calendar.current.date(byAdding: .day, value: -11, to: .now)!, channel: .blaze, isRead: false),

        // Marc thread
        Message(id: UUID(), contactId: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, body: "The Dreamforce slot is yours Tony. September 15-17. I want you to close the whole conference — main stage final keynote.", isFromTony: false, sentAt: Calendar.current.date(byAdding: .day, value: -5, to: .now)!, channel: .blaze, isRead: true),
        Message(id: UUID(), contactId: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, body: "Marc — honored. Let's also talk about the chapter idea. I think we're onto something real with conscious capitalism as the next frontier.", isFromTony: true, sentAt: Calendar.current.date(byAdding: .day, value: -5, to: .now)!, channel: .blaze, isRead: true),
    ]
}
