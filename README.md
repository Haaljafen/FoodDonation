App Name:
Takaffal

GitHub Link (Public Repository):
https://github.com/Haaljafen/FoodDonation.git

--------------------------------------------------------------
Group Members (Name + ID):
1. Hajar Aljafen – 202301297
2. Mariam Hashem – 202301956
3. Emama Mohammed – 202301722
4. Noora Humaid – 202301706
5. Abdulla Alaseeri – 202302860
6. Hussain Hejab – 202301136

--------------------------------------------------------------
Main Features (Developer + Tester):

1. Food Listing (Developer: Hajar Aljafen Tester: Mariam Hashem)
   - NGOs view available donations.
   - Donors submit food items with image, category, expiry date.
   - Accept/Reject UI components.
   - Item details page.

2. Notifications (Developer: Hajar Aljafen Tester: Mariam Hashem)
   - In-app notifications for donors, NGOs, and admins.
   - Shows message, time, and category.
   - Lock-screen style preview UI.

3. Authentication (Developer: Mariam Hashem Tester: Hajar Aljafen)
   - Login, Signup, Forgot Password.
   - Edit Profile & Change Password.
   - NGO Application flow.

4. Pickup Scheduling (Developer: Mariam Hashem Tester: Hajar Aljafen)
   - Donor selects pickup method (location-based pickup or drop-off at facility).
   - Donor selects pickup date and time.
   - Donor completes and creates a donation request.
   - Donation is saved with scheduling details for NGO review.


5. Search & Filtering (Developer: Emama Mohammed Tester: Noora Humaid)
   - Search bar + multiple filters.
   - Saved searches.
   - Role-based filtering.

6. Recurring Donations (Developer: Emama Mohammed Tester: Noora Humaid)
   - Re-donate previous items with one tap.
   - Confirmation dialogs.
   - Works from History page.

7. Organization Discovery (Developer: Abdulla Alaseeri Tester: Hussain Hejab)
   - View list of verified NGOs.
   - NGO profile: mission, details, stats.

8. Admin Panel (Developer: Abdulla Alaseeri Tester: Hussain Hejab)
   - Manage users (view/update/suspend).
   - Verify NGOs.
   - View system reports.

9. Achievements (Developer: Hussain Hejab Tester: Abdulla Alaseeri)
   - Achievement badges.
   - Contribution progress.

10. AI Chatbot (Developer: Hussain Hejab Tester: Abdulla Alaseeri)
   - Food donation Q&A.
   - SDG 2 & SDG 12 guidance.

11. Real-Time Donation Status (Developer: Noora Humaid Tester: Emama Mohammed)
   - Collector updates donation status.
   - Donor tracks updates in a timeline view.

12. Impact Tracking (Developer: Noora Humaid Tester: Emama Mohammed)
   - User impact dashboard.
   - Admin system-wide impact view.

--------------------------------------------------------------
Extra Features:

1. QR Receipt & Donation Proof (Developer: Hajar Aljafen)
   - After a donor creates a donation, a QR code is generated containing
     the donation receipt as proof.
   - When an NGO accepts the donation, a separate QR code is generated
     to serve as proof of acceptance.
   - These QR codes enhance transparency, traceability, and trust between
     donors and NGOs.

1. Calendar (Developer: Hajar Aljafen)
   - A dedicated iOS-style Month Calendar is accessible from the header calendar icon across the app.
   - Users can add personal agenda events with the (+)
   - Scheduled pickup and drop-off requests appear.
   - Donation expiry dates are automatically added as calendar events labeled “Expires”.
     
--------------------------------------------------------------
Design Changes:

- Minor UI adjustments were made compared to the prototype due to Auto Layout
  constraints and usability improvements.
- Button sizing and spacing were unified to ensure visual consistency
  across different screen sizes.
- Switched from a checkbox-based donation status pipeline to action buttons
  for NGOs to progress donation status.
- Donation status progression is now controlled through explicit actions,
  preventing status skipping and enforcing business rules.
- Accept and Reject actions were moved exclusively to the donation
  details screen to prevent accidental acceptance or rejection.

Reasons for these changes:
- To enforce clearer business logic and prevent invalid state transitions.
- To improve user experience and reduce accidental actions.
- To provide a more scalable and maintainable interaction model.

--------------------------------------------------------------
Libraries, Packages, External Code:
- Firebase Authentication
- Firebase Firestore
- Cloudinary
- DGCharts

--------------------------------------------------------------
Setup Instructions:
1. Clone the repository from GitHub.
2. Open the project using Xcode 16 or later.
3. Ensure an active internet connection for Firebase services.
4. Run the app on a simulator with iOS 17.0 or later.

--------------------------------------------------------------
Simulators Used for Testing:
- iPhone 16 Pro

--------------------------------------------------------------
Login Credentials
------------------------------------------------------------

| Role   | Email               | Password    |
|--------|---------------------|-------------|
| Admin  | admin@takaffal.com  | admin@123   |
| Donor  | emama25@gmail.com   | emama@123   |
| NGO    | kaaf@kaaf.com       | kaaf@123    |


