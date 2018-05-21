% FORMAT_BY_CLASS             Format data by class assignment
% 
%     data = format_by_class(dp,dn);
%
%     INPUTS
%     dp   - scores for "signal" distribution
%     dn   - scores for "noise" distribution
%
%     OUTPUTS
%     data - [class , score] matrix
%     

%     $ Copyright (C) 2011 Brian Lau http://www.subcortex.net/ $
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%     REVISION HISTORY:
%     brian 03.08.08 written

function data = format_by_class(dp,dn);

dp = dp(:);
dn = dn(:);

y = [dp ; dn];
t = logical([ ones(size(dp)) ; zeros(size(dn)) ]);

data = [t,y];