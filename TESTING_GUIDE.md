# Testing Guide for Content Upload Feature

## Pre-Testing Checklist
- ✅ Xcode project builds successfully
- ✅ No compilation errors
- ✅ Running on iOS device or simulator (iOS 15.0+)

## Test Scenarios

### 1. Text Content
**Test Case 1.1: Create Text Lesson**
- [ ] Navigate to Course Structure
- [ ] Expand a module
- [ ] Add new lesson named "Introduction"
- [ ] Click "Content" button
- [ ] Select "Text" from menu
- [ ] Verify Content Editor opens
- [ ] Type some text content
- [ ] Click "Save Content"
- [ ] Verify success alert appears
- [ ] Verify green checkmark appears on lesson
- [ ] Verify button changes to "Edit"

**Test Case 1.2: Edit Text Content**
- [ ] Click "Edit" on text lesson
- [ ] Verify existing content loads
- [ ] Modify the text
- [ ] Save
- [ ] Verify changes persist

**Test Case 1.3: Empty Text Validation**
- [ ] Open text content editor
- [ ] Clear all text
- [ ] Verify "Save Content" button is disabled

---

### 2. Video Content
**Test Case 2.1: Upload Video**
- [ ] Create/select a lesson
- [ ] Click "Content" → Select "Video"
- [ ] Verify Content Editor opens with upload area
- [ ] Tap upload area
- [ ] Verify iOS document picker opens
- [ ] Select a video file (MP4 or MOV)
- [ ] Verify file name appears with green checkmark
- [ ] Add description text
- [ ] Click "Save Content"
- [ ] Verify success and green checkmark on lesson

**Test Case 2.2: Remove Video**
- [ ] Open video content editor with uploaded file
- [ ] Click "Remove File" button
- [ ] Verify file is cleared
- [ ] Verify upload area returns to default state

**Test Case 2.3: Video Size Limit**
- [ ] Try uploading a video > 100MB
- [ ] Verify rejection or warning (check console logs)

---

### 3. PDF Content
**Test Case 3.1: Upload PDF**
- [ ] Create/select a lesson
- [ ] Click "Content" → Select "PDF"
- [ ] Tap upload area
- [ ] Verify only PDF files are shown in picker
- [ ] Select a PDF
- [ ] Verify file name appears
- [ ] Add description
- [ ] Save
- [ ] Verify success

**Test Case 3.2: PDF Size Limit**
- [ ] Try uploading a PDF > 50MB
- [ ] Verify rejection (check console)

---

### 4. Presentation Content (Keynote)
**Test Case 4.1: Upload Keynote**
- [ ] Create/select a lesson
- [ ] Click "Content" → Select "Presentation"
- [ ] Tap upload area
- [ ] Select a .key file (Keynote) or .pptx file
- [ ] Verify file name appears
- [ ] Add description
- [ ] Save
- [ ] Verify success

**Test Case 4.2: PowerPoint Support**
- [ ] Try uploading .ppt file
- [ ] Try uploading .pptx file
- [ ] Verify both work

---

### 5. Quiz Content (Ensure Not Broken)
**Test Case 5.1: Quiz Creation**
- [ ] Create/select a lesson
- [ ] Click "Content" → Select "Quiz"
- [ ] Verify navigates to Quiz Editor (NOT Content Editor)
- [ ] Verify quiz creation still works
- [ ] Add questions
- [ ] Save quiz

**Test Case 5.2: Edit Existing Quiz**
- [ ] Find lesson with quiz type
- [ ] Click "Edit Quiz" button
- [ ] Verify navigates to Quiz Editor
- [ ] Verify questions load correctly

---

### 6. Content Type Switching
**Test Case 6.1: Change from Text to Video**
- [ ] Create text lesson with content
- [ ] Click "Edit" → Go back
- [ ] Click "Content" → Select "Video"
- [ ] Verify opens video editor (text content should be cleared)
- [ ] Upload video
- [ ] Save

**Test Case 6.2: Change from Video to PDF**
- [ ] Create video lesson
- [ ] Change type to PDF
- [ ] Verify video data is cleared
- [ ] Upload PDF

---

### 7. Navigation Tests
**Test Case 7.1: From CourseStructureView**
- [ ] Navigate via CourseStructureView
- [ ] Select content type
- [ ] Edit content
- [ ] Go back
- [ ] Verify returns to CourseStructureView

**Test Case 7.2: From LessonDetailView**
- [ ] Navigate to LessonDetailView
- [ ] Select content type (non-Quiz)
- [ ] Verify navigates to Content Editor
- [ ] Save and go back
- [ ] Verify returns correctly

---

### 8. UI/UX Tests
**Test Case 8.1: Visual Indicators**
- [ ] Verify green checkmark shows only on lessons with content
- [ ] Verify button text changes ("Content" vs "Edit")
- [ ] Verify content type icons display correctly

**Test Case 8.2: File Upload UI**
- [ ] Verify dashed border on empty upload area
- [ ] Verify solid green border after file selection
- [ ] Verify file icon changes based on type

**Test Case 8.3: Placeholders**
- [ ] Verify placeholder text shows in empty text editor
- [ ] Verify placeholder text shows in empty description field

---

### 9. Edge Cases
**Test Case 9.1: Very Long Text**
- [ ] Enter 5000+ characters in text editor
- [ ] Verify scrolling works
- [ ] Verify save works

**Test Case 9.2: Special Characters in Filename**
- [ ] Upload file with special characters in name
- [ ] Verify handles correctly

**Test Case 9.3: Rapid Navigation**
- [ ] Quickly switch between content types
- [ ] Verify no crashes
- [ ] Verify correct editor loads

---

### 10. Data Persistence
**Test Case 10.1: Content Survives Navigation**
- [ ] Add content to lesson
- [ ] Navigate away from course
- [ ] Navigate back to same lesson
- [ ] Verify content still exists

**Test Case 10.2: Multiple Lessons**
- [ ] Add different content types to 5 different lessons
- [ ] Verify each maintains its own content
- [ ] Verify no data mixing between lessons

---

## Known Limitations (Current Implementation)
1. Files are stored as local paths, not uploaded to cloud
2. No progress indicator during file selection
3. No file preview (video/PDF/Keynote)
4. No video thumbnail generation
5. File size limits are client-side only

## Debug Tips
- Check Xcode console for file picker errors
- Use breakpoints in `saveContent()` method
- Verify `hasContent` computed property works
- Check navigation state variables

## Reporting Issues
When reporting bugs, include:
1. Device/Simulator details
2. iOS version
3. Exact steps to reproduce
4. Expected vs actual behavior
5. Console logs (if any)
6. Screenshots/screen recordings

## Success Criteria
✅ All content types can be added
✅ Content persists after saving
✅ Navigation works smoothly
✅ Quiz functionality unchanged
✅ No crashes or errors
✅ UI indicators work correctly
✅ File pickers open and work
✅ Validation works as expected
